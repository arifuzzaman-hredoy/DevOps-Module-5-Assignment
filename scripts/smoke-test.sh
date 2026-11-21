#!/usr/bin/env bash
# Post-deployment smoke test through the public Nginx entry point.
# Usage: ./scripts/smoke-test.sh [base_url]
set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

URL="${1:-$(gateway_url)}"
failures=0
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

check_json() {
  local path="$1" pattern="$2" code
  code="$(curl -s -o "$body_file" -w '%{http_code}' "$URL$path" || echo 000)"
  if [ "$code" = "200" ] && grep -q "$pattern" "$body_file"; then
    ok "GET $path -> 200 (matched: $pattern)"
  else
    warn "GET $path -> HTTP $code (expected 200 matching '$pattern')"
    failures=$((failures + 1))
  fi
}

check_status() {
  local path="$1" expected="$2" code
  code="$(curl -s -o /dev/null -w '%{http_code}' "$URL$path" || echo 000)"
  if [ "$code" = "$expected" ]; then
    ok "GET $path -> $expected"
  else
    warn "GET $path -> HTTP $code (expected $expected)"
    failures=$((failures + 1))
  fi
}

log "Smoke testing $URL"
check_status /healthz 200
check_json   /api/info 'ShopNest API'
check_json   /api/products '"id"'
check_json   /api/products/1 '"name"'
check_status / 200
check_status /products/1 200
check_status /api/products/999999 404

if [ "$failures" -ne 0 ]; then
  die "$failures smoke test(s) failed"
fi
ok "All smoke tests passed"