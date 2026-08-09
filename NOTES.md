# Architectural discussion

Answers to the four questions in the assignment. The practical setup and how to bring it up
from scratch are in the [README](./README.md)

---

## 1. Trade-offs

*What parts of the implementation did you decide to skip or simplify, and why?*

The brief asks for one or two optional extensions; Resilience and CI/CD were the two chosen,
so Ingress/TLS and the database were left out rather than half-built. Both were cut for time,
not because the approach was unclear.

**TLS.** Where it terminates decides the implementation. Inside the cluster, cert-manager
issues and renews the certificate into a Secret the Ingress references. On AWS the more usual
choice is to terminate at the load balancer: the AWS Load Balancer Controller provisions an
ALB from the Ingress and an ACM certificate is referenced by annotation, so no private key is
ever handled in the cluster.

**The database.** Locally this would have been a PostgreSQL StatefulSet — a headless Service
giving the pod a stable FQDN, that FQDN as the application's database host, the database and
role created on first start, and `volumeClaimTemplates` for per-pod persistence. On AWS none
of that applies: the workload becomes Amazon RDS, the host is the instance endpoint, and
provisioning, backups, failover and patching stop being the cluster's problem.

---

## 2. Local vs AWS Production

*Name 3–5 concrete things that are currently "test-only" in the local setup but would be
handled differently in a true AWS production environment.*

**The resilience numbers are demo values, not sized ones.** The HPA target, the PDB budget and
the rollout's `maxSurge`/`maxUnavailable` are reasoned from first principles against a dummy
workload. In production each one comes from observed traffic and latency, agreed with the
application team rather than chosen by whoever writes the chart, and they differ per service.

**There is no observability.** metrics-server is deployed because the HPA cannot function
without it, and that is the extent of it — nothing collects metrics, logs or traces, and there
is no alerting.

**A production EKS cluster runs a platform layer this one does not have.** external-dns for
Route 53 records, the AWS Load Balancer Controller for Ingress, Karpenter or Cluster
Autoscaler for node capacity, KEDA where CPU utilisation is not the right scaling signal,
Argo CD for delivery, cert-manager if certificates are issued in-cluster. The minikube addons
stand in for two of these; the rest have no local equivalent.

**The surrounding architecture is out of scope entirely.** How clients reach the application,
whether it is deployed multi-region, the VPC and subnet layout, the L4 and L7 boundaries —
security groups, NACLs, WAF — and least-privilege IAM throughout are the decisions a real
deployment starts from. Here there is a single-node cluster on a laptop: no network boundary,
no identity model, and every pod reachable from every other one.

---

## 3. AWS Security & Secrets

*How would you securely pass secrets to pods in AWS EKS? (e.g., AWS Secrets Manager + External Secrets Operator vs CSI Driver, IAM Roles for Service Accounts). What is your preferred approach?*

Both options agree on the part that matters most: the identity is a Kubernetes ServiceAccount
mapped to an IAM role through IRSA, so nothing in the cluster holds a static AWS credential
and the grant can be scoped to one secret path rather than to Secrets Manager as a whole.

**Secrets Store CSI Driver.** A `SecretProviderClass` names the secrets; the driver fetches
them when the pod starts and mounts them as files in a tmpfs volume. The pod's own
ServiceAccount is the identity, so each workload authorises only for what it needs, and the
material never becomes a Kubernetes object — it is not in etcd, not in an etcd backup, and not
readable with `kubectl get secret`. It disappears with the pod.

**External Secrets Operator.** A controller reconciles an `ExternalSecret` into a native
Kubernetes Secret. Any workload then consumes it by name without knowing where it came from,
env vars work normally, and a rotation produces a real Secret change that a checksum
annotation can turn into a rollout. The IAM role sits on the operator, not the application, so
one component holds the read permission for everything it syncs.

**Preference: the CSI driver**, which is also what I have run in practice. Keeping the value
out of etcd is the stronger default, and attaching the role to the workload's own
ServiceAccount rather than to a shared operator keeps least privilege per workload instead of
concentrating it. The honest costs: delivery is coupled to a volume mount, consuming a secret
as an environment variable needs `secretObjects`, which creates the Kubernetes Secret again
and gives back the etcd exposure, and rotation is an opt-in driver feature the application
must still notice.

That last cost is why the infrastructure here installs ESO rather than the CSI driver — this
chart consumes its secret as an environment variable via `secretKeyRef`, and RDS generates its
master password straight into Secrets Manager, so something has to turn that into a Kubernetes
Secret the pod can reference. The chart's `secrets.existingSecret` is the seam for whichever
of the two produces it. The preference above is the default I would start from; this
application's consumption model is the reason it is not what got built.

---

## 4. Infrastructure as Code

*If you had to provision the AWS infrastructure (VPC, EKS cluster, RDS) for this app tomorrow,
what tool would you choose and how would you structure the project?*

**OpenTofu/Terraform for the resources, Terragrunt for the wiring.** Terraform alone means
either one large root module per environment or a copied `backend.tf` and `provider.tf` in
every component directory. Terragrunt declares both once and generates them per component,
without adding a second language for describing resources.

Three layers: `tf-modules/stacks/` is **what** a component is, `tg-modules/` is **how** it is
configured everywhere, `namespaces/` is **where** it is deployed. Environments are separate
AWS accounts.

Rather than describe it, I built it — [`cloud-setup/`](./cloud-setup/), with
[its README](./cloud-setup/README.md) as the full write-up. Never applied: no AWS account, so
no account IDs, no ARNs, no state.
