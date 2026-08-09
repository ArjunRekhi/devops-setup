# podinfo on Kubernetes

[podinfo](https://github.com/stefanprodan/podinfo) deployed to a local minikube cluster via a
Helm chart, with notes on migrating it to AWS.

## Prerequisites

Docker, minikube, kubectl, helm.

## Bring it up

```bash
bash cluster/minikube-up.sh
helm upgrade --install podinfo application/charts/podinfo-app -n podinfo --create-namespace --atomic --wait --timeout 5m
bash application/verification-scripts/verify.sh
```

Tear down with `bash cluster/minikube-down.sh`.

To supply real secret values:

```bash
cp application/charts/podinfo-app/values-secret.yaml.example application/charts/values-secret.yaml
helm upgrade --install podinfo application/charts/podinfo-app -n podinfo -f application/charts/values-secret.yaml --atomic --wait
```

The copy is gitignored. Keys must match `values.yaml` exactly — a wrong key is silently
ignored rather than rejected.

## Layout

| Path | |
|------|--|
| `cluster/` | Cluster create/delete scripts |
| `application/charts/podinfo-app/` | The Helm chart |
| `application/manifests/` | The same workload as static YAML, for reference |
| `application/verification-scripts/verify.sh` | Port-forwards and curls the endpoints |
| `application/verification-scripts/demo-resilience.sh` | Readiness, liveness and PDB behaviour |
| `application/verification-scripts/demo-hpa.sh` | Drives load so the HPA reacts |
| `.gitlab-ci.yml` · `ci-cd/` | Pipeline to ECR and Nexus — written, never run |
| `cloud-setup/` | Terraform + Terragrunt layout for the AWS side — written, never applied |
| `documentation/` | Write-ups and command references |

## Documentation

1. [Cluster setup](./documentation/01-minikube-setup.md)
2. [Helm packaging, config and secrets](./documentation/02-helm-overview.md)
3. [CI/CD — ECR, Nexus, Argo CD](./documentation/03-cicd.md)

Command references: [minikube](./documentation/minikube-commands.md) ·
[helm](./documentation/helm-commands.md)

The four architectural questions are answered in [NOTES.md](./NOTES.md). The AWS
infrastructure that answers the last of them lives in
[`cloud-setup/`](./cloud-setup/README.md).

## Key points

- Image pinned, never `:latest` — `image.tag` is empty and falls back to `Chart.appVersion`,
  which CI stamps at package time.
- Non-sensitive config in a ConfigMap via `envFrom`; the secret pulled key-by-key via
  `secretKeyRef`. `secrets.existingSecret` is the seam an external secrets manager plugs into.
- Config and secret content hashed into pod annotations, so a config change is a real rollout.
- Startup, liveness and readiness probes tuned differently on purpose.
- CPU request with no CPU limit; memory `limit == request`.
- HPA on CPU, plus a PodDisruptionBudget using `maxUnavailable`.
- No PVC — podinfo is stateless; persistence belongs with the database.
- CI ends at publishing the packaged chart to Nexus; Argo CD reconciles it into EKS, so no
  pipeline job holds cluster credentials.
- AWS access via GitLab OIDC — short-lived credentials, no keys stored as CI variables.

Reasoning is in [02-helm-overview.md](./documentation/02-helm-overview.md) and
[03-cicd.md](./documentation/03-cicd.md).

## Not done yet

Pod/container security context, Ingress and TLS, and the database.
