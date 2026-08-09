# podinfo on Kubernetes

[podinfo](https://github.com/stefanprodan/podinfo) deployed to a local minikube cluster via a
Helm chart, with a CI pipeline and an AWS infrastructure layout alongside it.

## Run it

Needs Docker, minikube, kubectl and helm.

```bash
bash kubernetes-application/cluster-setup/minikube-up.sh
helm upgrade --install podinfo kubernetes-application/charts/podinfo-app -n podinfo --create-namespace --atomic --wait --timeout 5m
bash kubernetes-application/verification-scripts/verify.sh
```

## Layout

| Path | |
|------|--|
| `kubernetes-application/` | Cluster scripts, the Helm chart, the same workload as static YAML, and verification scripts |
| `.gitlab-ci.yml` · `ci-cd/` | Pipeline to ECR and Nexus — written, never run |
| `cloud-workloads/` | Terraform + Terragrunt for the AWS side — written, never applied |
| `documentation/` | Write-ups and command references |

## Key Points

- **Local setup complete.** One script up, one command to install, one script to prove the endpoints, probes, HPA and PDB actually behave. Secrets and ConfigMaps are kept in different files, and image and Kubernetes versions are pinned.
- **No pipeline job holds cluster credentials.** CI stops at publishing the chart; Argo CD pulls it into EKS, and AWS access is short-lived via GitLab OIDC.
- **CI/CD and cloud setup.** Both layers are written but were never executed, and both would change once scaled to enterprise level.
- **TLS and Postgres.** Not implemented — how they would work is explained instead, based on practical experience.

## Documentation

The reasoning behind every decision above lives here:

1. [Cluster setup](./documentation/01-minikube-setup.md)
2. [Helm packaging, config and secrets](./documentation/02-helm-overview.md)
3. [CI/CD — ECR, Nexus, Argo CD](./documentation/03-cicd.md)
4. [AWS infrastructure](./cloud-workloads/README.md)

The four architectural questions are answered in [NOTES.md](./NOTES.md). Command references:
[minikube](./documentation/minikube-commands.md) · [helm](./documentation/helm-commands.md).
