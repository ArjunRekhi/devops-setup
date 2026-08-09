#!/usr/bin/env bash
#
# Shows the resilience settings doing something rather than just existing.
#
#   readiness   -- pod leaves the Service endpoints but keeps Running
#   liveness    -- kubelet restarts the container
#   disruption  -- how much voluntary disruption the PDB permits
#
# Works whether the app was installed with Helm or applied with kubectl.
#
# Usage: bash application/verification-scripts/demo-resilience.sh [readiness|liveness|disruption|all]
#
set -euo pipefail

NAMESPACE="${NAMESPACE:-podinfo}"
APP="${APP:-podinfo}"
CHART="${CHART:-application/charts/podinfo-app}"
SCENARIO="${1:-all}"

# The chart does not set app.kubernetes.io/instance -- resource names are fixed
# rather than release-prefixed -- so pods are selected by name only.
SELECTOR="app.kubernetes.io/name=${APP}"

k() { kubectl -n "${NAMESPACE}" "$@"; }
hr() { printf '\n%s\n' "=============================================================="; }

# Via port-forward from the host, so this does not depend on which CLI tools
# exist inside the image.
pod_request() {
  local pod="$1" method="$2" path="$3" port="18080" pid
  kubectl -n "${NAMESPACE}" port-forward "pod/${pod}" "${port}:9898" >/dev/null 2>&1 &
  pid=$!
  for _ in {1..30}; do
    curl -fsS --max-time 2 "http://127.0.0.1:${port}/healthz" >/dev/null 2>&1 && break
    sleep 0.3
  done
  curl -fsS --max-time 5 -X "${method}" "http://127.0.0.1:${port}${path}" || true
  kill "${pid}" 2>/dev/null || true
  wait "${pid}" 2>/dev/null || true
}

# EndpointSlice is what the Service actually routes on.
endpoints() {
  k get endpointslice -l "kubernetes.io/service-name=${APP}" \
    -o jsonpath='{range .items[*].endpoints[*]}  {.targetRef.name}{"\t"}{.conditions.ready}{"\n"}{end}'
}

first_pod() {
  k get pod -l "${SELECTOR}" --field-selector=status.phase=Running \
    -o jsonpath='{.items[0].metadata.name}'
}

# Both install paths label the Deployment, so the method is self-describing:
# the chart sets managed-by=Helm, the raw manifests set managed-by=kubectl.
managed_by() {
  k get deploy "${APP}" \
    -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}' 2>/dev/null
}

# Changes the liveness probe path through whichever tool owns the release.
# Going through Helm when Helm owns it matters: a kubectl patch would be drift,
# silently reverted by the next `helm upgrade`.
set_liveness_path() {
  if [[ "$(managed_by)" == "Helm" ]]; then
    # No --wait: the pods are supposed to go unhealthy.
    helm upgrade "${APP}" "${CHART}" \
      --namespace "${NAMESPACE}" --reuse-values \
      --set probes.liveness.path="$1" >/dev/null
  else
    k patch deploy "${APP}" --type=json \
      -p="[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/livenessProbe/httpGet/path\",\"value\":\"$1\"}]" \
      >/dev/null
  fi
}

demo_readiness() {
  hr; echo "READINESS: failing pod leaves the Service, stays Running"
  local pod; pod=$(first_pod)
  if [[ -z "${pod}" ]]; then echo "no running pods matching ${SELECTOR}" >&2; return 1; fi
  echo "Target: ${pod}"

  echo; echo "Endpoints before:"; endpoints
  echo; echo "POST /readyz/disable"
  pod_request "${pod}" POST /readyz/disable; echo

  sleep 15   # period 5s x threshold 2
  echo; echo "Endpoints after:"; endpoints

  echo; echo "Still Running, never restarted — readiness only controls traffic:"
  k get pod "${pod}" -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount

  echo; echo "POST /readyz/enable"
  pod_request "${pod}" POST /readyz/enable; echo
  sleep 10
  echo "Endpoints restored:"; endpoints
}

demo_liveness() {
  hr; echo "LIVENESS: failing probe restarts the container"
  echo
  echo "Repointing the probe at /status/500 (always 500) rather than breaking the"
  echo "app — which also proves the probe path is a parameter, not a constant."
  echo "Applied via $(managed_by), the tool that owns this Deployment."

  set_liveness_path /status/500

  echo
  echo "First restart takes ~30s (period 10s x threshold 3). Slow on purpose:"
  echo "a hair-trigger liveness probe turns a blip into a restart storm."
  echo
  for _ in {1..24}; do
    k get pod -l "${SELECTOR}" \
      -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount,READY:.status.containerStatuses[0].ready \
      --no-headers | sed 's/^/  /'
    if k get pod -l "${SELECTOR}" \
        -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}' | grep -qE '[1-9]'; then
      echo "  -> restart observed"
      break
    fi
    sleep 5
  done

  echo
  k get events --field-selector reason=Unhealthy --sort-by=.lastTimestamp 2>/dev/null | tail -5 || true

  echo; echo "Reverting to /healthz"
  set_liveness_path /healthz
  k rollout status deploy/"${APP}" --timeout=3m
  k get pod -l "${SELECTOR}" --no-headers | sed 's/^/  /'
}

demo_disruption() {
  hr; echo "DISRUPTION: PodDisruptionBudget"
  k get pdb "${APP}" -o wide
  echo
  echo "ALLOWED DISRUPTIONS is how many pods may be evicted right now. A drain"
  echo "evicts one at a time and blocks at zero, which is what stops a rolling"
  echo "cluster upgrade from taking the service down."
  echo
  echo "Hence maxUnavailable over minAvailable: minAvailable: 2 against"
  echo "replicas: 2 permits zero disruption, so a drain hangs forever."
  echo
  echo "Voluntary disruption only — node failure, OOM kill and crashes bypass it."
  echo
  echo "Not shown: draining the node. minikube has one, so it would evict the"
  echo "control plane too. Real cluster: kubectl drain <node> --ignore-daemonsets"
}

case "${SCENARIO}" in
  readiness)  demo_readiness ;;
  liveness)   demo_liveness ;;
  disruption) demo_disruption ;;
  all)        demo_readiness; demo_liveness; demo_disruption ;;
  *) echo "usage: $0 [readiness|liveness|disruption|all]" >&2; exit 1 ;;
esac

hr
