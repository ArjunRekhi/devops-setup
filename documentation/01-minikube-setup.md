# Local Kubernetes Setup — minikube on macOS

Single-node Kubernetes cluster on an Apple Silicon Mac, using minikube with the
Docker Desktop driver.

**Date:** 2026-08-08
**Machine:** macOS 26 (Darwin 25.4.0), arm64

Command reference: [minikube-commands.md](./minikube-commands.md)

## Components

| Component | Version | Source |
|---|---|---|
| Docker Desktop | 4.85.0 (engine 29.6.2) | downloaded from docker.com |
| minikube | v1.38.1 | Homebrew |
| kubectl | v1.36.3 | Homebrew (`kubernetes-cli`) |
| Kubernetes | v1.35.1 | provisioned by minikube |

## Setup

**1. Install Docker Desktop**

Apple Silicon `.dmg` from
[docker.com](https://www.docker.com/products/docker-desktop), installed and
launched once. `docker info` confirms the daemon is up.

**2. Install minikube and kubectl**

```sh
brew install minikube kubectl
```

**3. Start the cluster**

The creation command lives in the repository, not only in this document, so the
environment is reproducible from a clean machine:

```sh
bash kubernetes-application/cluster-setup/minikube-up.sh
```

It is idempotent — re-running an existing profile only re-asserts the addons. It
wraps:

```sh
minikube start --profile=podinfo-demo --kubernetes-version=v1.35.1 --driver=docker --cpus=4 --memory=4096 --addons=metrics-server,ingress
```

Kubernetes is pinned rather than tracking `stable`. v1.35.1 is one minor behind
upstream and explicitly supported by the installed minikube — also closer to how
EKS works, since AWS does not ship a new minor on upstream release day.

Tear down with `bash kubernetes-application/cluster-setup/minikube-down.sh` (a full `minikube delete`, so the
next bring-up has to prove itself from scratch).

**4. Verify**

```sh
minikube status -p podinfo-demo
kubectl get nodes -o wide
```

## Resulting cluster

```
NAME           STATUS   ROLES           VERSION   INTERNAL-IP    CONTAINER-RUNTIME
podinfo-demo   Ready    control-plane   v1.35.1   192.168.49.2   docker://29.2.1
```

- **Profile:** `podinfo-demo` — 1 node, driver `docker`, runtime `docker`
- **Node OS:** Debian GNU/Linux 12 (bookworm), kernel 6.12.76-linuxkit
- **kubeconfig:** context `podinfo-demo` written to `~/.kube/config` and set active
- **Addons enabled:** `default-storageclass`, `storage-provisioner` (both on by
  default), plus `metrics-server` and `ingress` (enabled by the script)

`metrics-server` is not installed by default and is required by the
HorizontalPodAutoscaler — without it the HPA reports `TARGETS: <unknown>` and never
acts. `ingress` installs the ingress-nginx controller, used later.

The single node is both control plane and worker, so workloads schedule directly
onto it.

## Known limitation

On macOS with the Docker driver the node IP (`192.168.49.2`) is not routable from
the host. Reaching a Service means `kubectl port-forward`, and Ingress requires
`minikube tunnel` in a separate terminal (needs sudo) or a port-forward to the
ingress-nginx controller.
