#!/usr/bin/env bash
#
# Destroys the local cluster. A full delete rather than `minikube stop`, so the
# next bring-up has to prove itself from scratch.
#
set -euo pipefail

PROFILE="${PROFILE:-podinfo-demo}"

echo "==> Deleting minikube profile '${PROFILE}'"
minikube stop --profile="${PROFILE}"
