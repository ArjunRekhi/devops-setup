#!/usr/bin/env bash
#
# Smoke-tests the running deployment through a temporary port-forward.
# Works whether the app was installed with Helm or applied with kubectl.
# Exits non-zero on failure, so it is safe to wire into CI.
#
set -euo pipefail

NAMESPACE="${NAMESPACE:-podinfo}"
APP="${APP:-podinfo}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
BASE="http://127.0.0.1:${LOCAL_PORT}"

cleanup() {
  if [[ -n "${PF_PID:-}" ]] && kill -0 "${PF_PID}" 2>/dev/null; then
    kill "${PF_PID}" 2>/dev/null || true
    wait "${PF_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

kubectl -n "${NAMESPACE}" wait --for=condition=available \
  --timeout=120s "deployment/${APP}"

# The chart labels its objects managed-by=Helm, the raw manifests managed-by=kubectl.
echo "Deployed by: $(kubectl -n "${NAMESPACE}" get deploy "${APP}" \
  -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}')"
echo

kubectl -n "${NAMESPACE}" port-forward "svc/${APP}" "${LOCAL_PORT}:9898" >/dev/null 2>&1 &
PF_PID=$!

for _ in {1..30}; do
  curl -fsS "${BASE}/healthz" >/dev/null 2>&1 && break
  sleep 0.5
done

check() {
  printf '  %-24s ' "$2"
  if body=$(curl -fsS --max-time 5 "${BASE}$1"); then
    echo "OK  ${body:0:70}"
  else
    echo "FAILED"
    return 1
  fi
}

check /healthz "GET /healthz"
check /readyz  "GET /readyz"
check /version "GET /version"

echo
echo "Config injected from the ConfigMap:"
curl -fsS --max-time 5 "${BASE}/env" \
  | tr -d '[]"' | tr ',' '\n' | grep -E 'PODINFO_UI' || true

echo
echo "OK — ${BASE} serves the UI."
