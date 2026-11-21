#!/usr/bin/env bash
# Safe failure-scenario harness. Run against STAGING or a local stack only.
# Never point this at production.
#
# Usage: ./scripts/failure-scenarios.sh [all|bad-image|post-switch-failure|inactive-down|rollback]
set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
cd "$PROJECT_ROOT"

SCENARIO="${1:-all}"

scenario_bad_image() {
  log "Scenario: deploy a non-existent image tag -> must fail safely"
  local before after
  before="$(active_color)"
  if IMAGE_TAG="this-tag-does-not-exist" PULL_IMAGES=true \
      "$SCRIPT_DIR/bg-deploy.sh" "this-tag-does-not-exist" 2>&1 | sed 's/^/    /'; then
    die "Expected a bad-image deployment to fail"
  fi
  after="$(active_color)"
  [ "$before" = "$after" ] || die "Active colour changed after a failed deploy ($before -> $after)"
  ok "Active colour unchanged ($after); production traffic unaffected"
}

scenario_post_switch_failure() {
  log "Scenario: forced post-switch health failure -> automatic rollback"
  local before after
  before="$(active_color)"
  if SIMULATE_FAILURE=post "$SCRIPT_DIR/bg-deploy.sh" "${IMAGE_TAG:-latest}" 2>&1 | sed 's/^/    /'; then
    die "Expected a simulated post-switch failure"
  fi
  after="$(active_color)"
  [ "$before" = "$after" ] || die "Automatic rollback did not restore '$before' (now '$after')"
  public_health || die "Public health check failed after rollback"
  ok "Automatic rollback restored '$after' and public health is OK"
}

scenario_inactive_down() {
  log "Scenario: kill the inactive colour -> active traffic must be unaffected"
  local active inactive
  active="$(active_color)"
  inactive="$(other_color "$active")"
  compose kill "$inactive-backend" "$inactive-frontend" >/dev/null 2>&1 || true
  if public_health; then
    ok "Active colour '$active' still serving while '$inactive' is down"
  else
    die "Active traffic was affected when '$inactive' went down"
  fi
}

scenario_manual_rollback() {
  log "Scenario: manual rollback to the standby colour"
  "$SCRIPT_DIR/rollback.sh"
}

case "$SCENARIO" in
  all)                 scenario_bad_image; scenario_post_switch_failure; scenario_inactive_down; scenario_manual_rollback ;;
  bad-image)           scenario_bad_image ;;
  post-switch-failure) scenario_post_switch_failure ;;
  inactive-down)       scenario_inactive_down ;;
  rollback)            scenario_manual_rollback ;;
  *) die "Unknown scenario '$SCENARIO'" ;;
esac

ok "Failure scenario '$SCENARIO' completed"