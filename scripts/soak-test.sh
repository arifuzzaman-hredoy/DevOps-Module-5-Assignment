#!/usr/bin/env bash
# Continuously send requests while a deployment runs to prove zero downtime.
# Usage: ./scripts/soak-test.sh [base_url] [duration_seconds] [interval_seconds]
set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

URL="${1:-$(gateway_url)}"
DURATION="${2:-60}"
INTERVAL="${3:-0.2}"

deadline=$((SECONDS + DURATION))
total=0
failures=0

log "Soak testing $URL for ${DURATION}s (every ${INTERVAL}s) ..."
while [ "$SECONDS" -lt "$deadline" ]; do
  code="$(curl -s -o /dev/null -w '%{http_code}' "$URL/api/info" || echo 000)"
  total=$((total + 1))
  if [ "$code" != "200" ]; then
    failures=$((failures + 1))
    warn "request #$total failed with HTTP $code"
  fi
  sleep "$INTERVAL"
done

log "Soak result: total=$total failures=$failures"
if [ "$failures" -eq 0 ]; then
  ok "Zero failed requests during the soak window"
else
  die "$failures of $total requests failed"
fi