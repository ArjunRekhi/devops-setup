# podinfo on Kubernetes

[podinfo](https://github.com/stefanprodan/podinfo) deployed to a local minikube cluster via a
Helm chart, with a CI pipeline and an AWS infrastructure layout alongside it.

## Run it

Needs Docker, minikube, kubectl and helm.

```bash
bash cluster/minikube-up.sh
helm upgrade --install podinfo application/charts/podinfo-app -n podinfo --create-namespace --atomic --wait --timeout 5m
bash application/verification-scripts/verify.sh
```

## Layout

| Path | |
|------|--|
| `cluster/` | Cluster create/delete scripts |
| `application/` | The Helm chart, the same workload as static YAML, and verification scripts |
| `.gitlab-ci.yml` · `ci-cd/` | Pipeline to ECR and Nexus — written, never run |
| `cloud-setup/` | Terraform + Terragrunt for the AWS side — written, never applied |
| `documentation/` | Write-ups and command references |

## What this is meant to show

- **It runs.** One script up, one command to install, one script to prove the endpoints, probes, HPA and PDB actually behave. Secrets and ConfigMaps are kept in different files
  and Kubernetes versions are fixed.
- **No pipeline job holds cluster credentials.** CI stops at publishing the chart; Argo CD
  pulls it into EKS, and AWS access is short-lived via GitLab OIDC.
- **The gaps are stated, not hidden.** Security context, Ingress/TLS and the database are out of scope; the CI and AWS layers are written but were never executed.

## Documentation

The reasoning behind every decision above lives here:

1. [Cluster setup](./documentation/01-minikube-setup.md)
2. [Helm packaging, config and secrets](./documentation/02-helm-overview.md)
3. [CI/CD — ECR, Nexus, Argo CD](./documentation/03-cicd.md)
4. [AWS infrastructure](./cloud-setup/README.md)

The four architectural questions are answered in [NOTES.md](./NOTES.md). Command references:
[minikube](./documentation/minikube-commands.md) · [helm](./documentation/helm-commands.md).
