#!/usr/bin/env bash
#
# Drives CPU load so the HPA has something to react to.
#
# Usage: bash kubernetes-application/verification-scripts/demo-hpa.sh
#
set -euo pipefail

NAMESPACE="${NAMESPACE:-podinfo}"
APP="${APP:-podinfo}"
DURATION="${DURATION:-300}"
WORKERS="${WORKERS:-4}"

kubectl -n "${NAMESPACE}" get hpa "${APP}"
echo
echo "TARGETS <unknown> means metrics-server has not scraped yet (~1 min)."
echo

# From inside the cluster, so load goes through the Service and spreads across
# replicas rather than through one port-forward.
echo "==> ${WORKERS} load generators for ${DURATION}s"
for i in $(seq 1 "${WORKERS}"); do
  kubectl -n "${NAMESPACE}" run "loadgen-${i}" \
    --image=busybox:1.36 --restart=Never --command -- \
    /bin/sh -c "end=\$(( \$(date +%s) + ${DURATION} )); while [ \$(date +%s) -lt \$end ]; do wget -q -O- http://${APP}:9898/ >/dev/null 2>&1; done" \
    >/dev/null
done

cleanup() {
  echo
  for i in $(seq 1 "${WORKERS}"); do
    kubectl -n "${NAMESPACE}" delete pod "loadgen-${i}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  done
  echo "Replicas stay high for ~2 min after load stops (scaleDown stabilisation)."
}
trap cleanup EXIT

kubectl -n "${NAMESPACE}" get hpa "${APP}" -w &
WATCH_PID=$!
sleep "${DURATION}"
kill "${WATCH_PID}" 2>/dev/null || true
