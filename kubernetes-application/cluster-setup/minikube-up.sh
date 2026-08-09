#!/usr/bin/env bash
#
# Creates the local cluster. Idempotent: re-running an existing profile only
# re-asserts the addons.
#
set -euo pipefail

# minikube profile name. minikube also creates a kubeconfig context of the same
# name, which is what the use-context line below selects.
PROFILE="${PROFILE:-podinfo-demo}"

# Pinned rather than "stable". One minor behind upstream and explicitly supported
# by the installed minikube — also closer to how EKS versions work, since Amazon
# does not ship a new minor on upstream release day.
K8S_VERSION="${K8S_VERSION:-v1.35.1}"

DRIVER="${DRIVER:-docker}"
CPUS="${CPUS:-4}"
MEMORY="${MEMORY:-4096}"

echo "==> Starting minikube profile '${PROFILE}' (k8s ${K8S_VERSION}, driver ${DRIVER})"
minikube start \
  --profile="${PROFILE}" \
  --kubernetes-version="${K8S_VERSION}" \
  --driver="${DRIVER}" \
  --cpus="${CPUS}" \
  --memory="${MEMORY}" \
  --addons=metrics-server,ingress

echo "==> Ensuring addons are enabled"
for addon in metrics-server ingress; do
  minikube addons enable "${addon}" --profile="${PROFILE}"
done

# minikube start already switches context; this keeps re-runs correct if you have
# since switched away manually.
kubectl config use-context "${PROFILE}"

echo
kubectl get nodes -o wide
echo