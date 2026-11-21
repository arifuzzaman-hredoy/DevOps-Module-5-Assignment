#!/usr/bin/env bash
# Shared helpers for the ShopNest blue-green deployment scripts.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env for local/manual runs without overriding values already exported by CI/CD.
if [ -f "$PROJECT_ROOT/.env" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*) continue ;;
    esac
    key="${line%%=*}"
    value="${line#*=}"
    if [ -z "${!key:-}" ]; then
      export "$key=$value"
    fi
  done < "$PROJECT_ROOT/.env"
fi

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

compose() {
  docker compose --project-directory "$PROJECT_ROOT" -f "$PROJECT_ROOT/docker-compose.yml" "$@"
}

# Returns "blue" or "green" based on the upstream configured in the public gateway.
active_color() {
  local conf="$PROJECT_ROOT/nginx/gateway/default.conf"
  grep -oE 'server (blue|green)-frontend:80' "$conf" 2>/dev/null \
    | head -n1 \
    | sed -E 's/server (blue|green)-frontend:80/\1/'
}

other_color() {
  [ "$1" = "blue" ] && echo green || echo blue
}

# Rewrites the gateway upstream and reloads Nginx gracefully (no dropped connections).
set_active_color() {
  local color="$1"
  local conf="$PROJECT_ROOT/nginx/gateway/default.conf"
  local tmp
  tmp="$(mktemp)"
  sed -E "s/server (blue|green)-frontend:80/server ${color}-frontend:80/" "$conf" > "$tmp"
  cat "$tmp" > "$conf"
  rm -f "$tmp"
  compose exec -T gateway nginx -t
  compose exec -T gateway nginx -s reload
}

wait_for_healthy() {
  local service="$1"
  local timeout="${2:-120}"
  local interval="${3:-3}"
  local cid status elapsed=0

  cid="$(compose ps -q "$service" 2>/dev/null | head -n1)"
  if [ -z "$cid" ]; then
    warn "Service '$service' has no container"
    return 1
  fi

  while [ "$elapsed" -lt "$timeout" ]; do
    status="$(docker inspect -f '{{.State.Health.Status}}' "$cid" 2>/dev/null || echo starting)"
    case "$status" in
      healthy)
        ok "Service '$service' is healthy"
        return 0
        ;;
      unhealthy)
        warn "Service '$service' is unhealthy"
        return 1
        ;;
    esac
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  warn "Service '$service' did not become healthy within ${timeout}s"
  return 1
}

gateway_url() {
  echo "http://localhost:${GATEWAY_PORT:-80}"
}

# End-to-end verification through the public Nginx entry point.
public_health() {
  curl -fsS "$(gateway_url)/healthz" >/dev/null 2>&1 || return 1
  curl -fsS "$(gateway_url)/api/info" 2>/dev/null | grep -q 'ShopNest API' || return 1
  curl -fsS "$(gateway_url)/api/products" 2>/dev/null | grep -q '"id"' || return 1
  return 0
}

require_env() {
  local name="$1"
  [ -n "${!name:-}" ] || die "Environment variable '$name' is required"
}