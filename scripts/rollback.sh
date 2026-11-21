#!/usr/bin/env bash
# Manual rollback to the previous (or a specific) release.
#
# Usage: ./scripts/rollback.sh [image_tag] [target_colour]
#   image_tag      Optional immutable tag to redeploy on the standby colour.
#   target_colour  Optional "blue" or "green". Defaults to the inactive colour.
set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TAG="${1:-}"
TARGET_COLOR="${2:-}"
cd "$PROJECT_ROOT"

current="$(active_color || true)"
[ -n "$current" ] || current=blue
target="${TARGET_COLOR:-$(other_color "$current")}"

log "Manual rollback requested. Current='$current' Target='$target'"

if [ -n "$TAG" ]; then
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
  if [ "$PULL_IMAGES" = "true" ]; then
    log "Pulling $TAG for '$target' ..."
    compose pull "$target-backend" "$target-frontend" || warn "Could not pull '$TAG'; using local images."
  fi
fi

compose up -d --no-deps "$target-backend" "$target-frontend" \
  || die "Failed to start '$target'"

wait_for_healthy "$target-backend" 150 || die "Rollback target backend is unhealthy."
wait_for_healthy "$target-frontend" 90 || die "Rollback target frontend is unhealthy."

if ! set_active_color "$target"; then
  set_active_color "$current" || true
  die "Traffic switch failed during rollback."
fi
sleep 2

if public_health; then
  ok "Rollback complete. Active colour: $target"
else
  warn "Rollback verification failed; restoring '$current'."
  set_active_color "$current" || true
  die "Rollback verification failed."
fi