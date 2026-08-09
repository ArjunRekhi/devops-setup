# Architectural discussion

Answers to the four questions in the assignment. The practical setup and how to bring it up
from scratch are in the [README](./README.md)

---

## 1. Trade-offs

*What parts of the implementation did you decide to skip or simplify, and why?*

**TLS and the database were left out for time.** Below is how I would approach each.

**TLS.** Where it terminates decides the implementation. Inside the cluster, cert-manager
issues and renews the certificate into a Secret that the Ingress references. On AWS the more
usual choice is to terminate at the load balancer, referencing the certificate in ACM.

**The database.** Locally this would have been a PostgreSQL StatefulSet exposed through a
headless Service, giving the pod a stable FQDN to use as the application's database host, with
`volumeClaimTemplates` for per-pod persistence. On AWS none of that applies: the workload
becomes Amazon RDS, the host is the instance endpoint, and provisioning, backups and failover
are mostly abstracted away.

---

## 2. Local vs AWS Production

*Name 3–5 concrete things that are currently "test-only" in the local setup but would be
handled differently in a true AWS production environment.*

**The resilience numbers are demo values, not sized ones.** The HPA target, the PDB budget and
the rollout's `maxSurge`/`maxUnavailable` are all set against a dummy workload. In production
each one comes from observed traffic and latency, agreed with the application team rather than
chosen by whoever writes the chart, and they differ per service.

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
deployment starts from.

---

## 3. AWS Security & Secrets

*How would you securely pass secrets to pods in AWS EKS? (e.g., AWS Secrets Manager + External Secrets Operator vs CSI Driver, IAM Roles for Service Accounts). What is your preferred approach?*

Both approaches authenticate to AWS through IRSA on the pod's ServiceAccount. The difference
is what ends up inside the cluster.

I have more experience with the **Secrets Store CSI driver**: the ServiceAccount authorises
the pull, the driver calls the AWS API and mounts the value as a file. The secret never
becomes a Kubernetes object, so it is not in etcd and not readable with `kubectl get secret`.

**External Secrets Operator** syncs into a real Kubernetes Secret instead. Env vars then work
normally, but the value sits in etcd and the IAM role belongs to the operator rather than the
workload — that is my reservation, not the duplication itself.

**Alternate: AWS AppConfig.** If AWS is the chosen cloud there is a third option. The secret
itself stays in Secrets Manager, and AppConfig serves it to the application through a
configuration profile that points at it. It is the more scalable and productionised route,
because the profiles are already scoped per microservice and per environment — and it covers
configuration in general, not only secrets.

**Preference.** AppConfig, where AWS is the chosen cloud. Otherwise either of the other two is
fine; I personally have more experience with the CSI driver.

---

## 4. Infrastructure as Code

*If you had to provision the AWS infrastructure (VPC, EKS cluster, RDS) for this app tomorrow,
what tool would you choose and how would you structure the project?*

**OpenTofu/Terraform for the resources, Terragrunt for the wiring.** Terraform alone means one
large root module per environment. Terragrunt keeps that **DRY**, which is what matters once
the infrastructure grows and has to stay consistent across environments.

Rather than describe it, I built it — [`cloud-setup/`](./cloud-setup/), with
[its README](./cloud-setup/README.md) as the full write-up. Never applied: no AWS account, so
no account IDs, no ARNs, no state.
