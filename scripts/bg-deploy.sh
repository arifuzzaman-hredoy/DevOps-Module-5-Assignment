#!/usr/bin/env bash
# Blue-Green deployment with health gating and automatic rollback.
#
# Usage: ./scripts/bg-deploy.sh [image_tag]
#   IMAGE_TAG         Immutable tag to deploy (default: $IMAGE_TAG or "latest").
#   PULL_IMAGES       "false" to skip registry pulls (local images). Default: true.
#   SIMULATE_FAILURE  "pre"  -> fail before traffic switch (new colour never goes live).
#                     "post" -> fail after traffic switch (exercises automatic rollback).
set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TAG="${1:-${IMAGE_TAG:-latest}}"
export IMAGE_TAG="$TAG"
export PULL_IMAGES="${PULL_IMAGES:-true}"

REGISTRY="${REGISTRY:-ghcr.io/arifuzzaman-hredoy}"
if [ -z "${BACKEND_IMAGE:-}" ]; then
  if [ "$PULL_IMAGES" = "false" ]; then
    export BACKEND_IMAGE="shopnest-app-backend:${TAG}"
  else
    export BACKEND_IMAGE="${REGISTRY}/shopnest-app-backend:${TAG}"
  fi
fi
if [ -z "${FRONTEND_IMAGE:-}" ]; then
  if [ "$PULL_IMAGES" = "false" ]; then
    export FRONTEND_IMAGE="shopnest-app-frontend:${TAG}"
  else
    export FRONTEND_IMAGE="${REGISTRY}/shopnest-app-frontend:${TAG}"
  fi
fi

cd "$PROJECT_ROOT"

current="$(active_color || true)"
[ -n "$current" ] || current=blue
target="$(other_color "$current")"

log "Current active colour : $current"
log "Deploying new release : $target (tag: $TAG)"
log "Backend image         : $BACKEND_IMAGE"
log "Frontend image        : $FRONTEND_IMAGE"

if [ "$PULL_IMAGES" = "true" ]; then
  log "Pulling images for '$target' ..."
  compose pull "$target-backend" "$target-frontend" \
    || die "Failed to pull images for '$target'"
fi

log "Starting '$target' environment ..."
compose up -d --no-deps "$target-backend" "$target-frontend" \
  || die "Failed to start '$target' containers"

if ! wait_for_healthy "$target-backend" 150; then
  warn "New backend failed its health checks; traffic was NOT switched."
  exit 1
fi
if ! wait_for_healthy "$target-frontend" 90; then
  warn "New frontend failed its health checks; traffic was NOT switched."
  exit 1
fi

log "Running internal smoke tests against '$target' ..."
compose exec -T "$target-frontend" wget -qO- http://127.0.0.1/api/info \
  | grep -q 'ShopNest API' || die "Smoke test failed: GET /api/info"
compose exec -T "$target-frontend" wget -qO- http://127.0.0.1/api/products \
  | grep -q '"id"' || die "Smoke test failed: GET /api/products"
ok "Internal smoke tests passed"

if [ "${SIMULATE_FAILURE:-}" = "pre" ]; then
  warn "SIMULATE_FAILURE=pre -> treating '$target' as failed before the traffic switch."
  exit 1
fi

log "Switching gateway traffic: $current -> $target"
if ! set_active_color "$target"; then
  warn "Traffic switch failed; restoring '$current'."
  set_active_color "$current" || true
  die "Traffic switch failed"
fi
sleep 2

if [ "${SIMULATE_FAILURE:-}" = "post" ]; then
  warn "SIMULATE_FAILURE=post -> failing post-switch verification; rolling back."
  if set_active_color "$current"; then
    ok "Automatic rollback to '$current' completed."
  fi
  die "Simulated post-switch failure (rolled back to '$current')"
fi

if public_health; then
  ok "Public health check passed on '$target'."
else
  warn "Public health check FAILED after switching to '$target'; rolling back to '$current'."
  set_active_color "$current" || true
  die "Deployment failed verification; rolled back to '$current'."
fi

log "Blue-Green deployment complete. Active colour: $target"