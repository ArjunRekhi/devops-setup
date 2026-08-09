# AWS infrastructure — Terraform + Terragrunt

A reference layout for provisioning AWS infrastructure with Terragrunt over Terraform.

The application here is podinfo, the same workload the Helm chart deploys locally, but it is
only an example. Nothing in the structure depends on it — the components are the ones a
typical service needs — and swapping the application means adding a `namespaces/<app>/`
directory, not changing the layers below it.

**None of this has been applied.** No AWS account was used, so there are no account IDs, no
ARNs and no state.

## Tool choice

**OpenTofu/Terraform for the resources, Terragrunt for the wiring.**

Terraform alone means either one large root module per environment, or a copy of `backend.tf`
and `provider.tf` in every directory. Terragrunt declares both once in `root.hcl` and
generates them into each component, without adding a second resource language.

## The three layers

| Layer | Answers | Contains |
|---|---|---|
| `tf-modules/stacks/` | *what* a component is | Terraform. No environment references these directly. |
| `tg-modules/` | *how* it is configured everywhere | Source pointer, inter-component dependencies, settings identical in all environments. |
| `namespaces/` | *where* it is deployed | One directory per environment. Only values that genuinely differ. |

Adding an environment is a directory of small files rather than a copy of the infrastructure.

## The hierarchy

```
namespaces/<app>/              namespace.hcl    — the application
└── non-production/            environment.hcl  — the tier
    └── dev/                   account.hcl      — the AWS account
        └── us-east-1/         region.hcl       — the region
            ├── network/
            ├── eks/
            ├── kubernetes-addons/
            ├── rds-postgres/
            ├── valkey/
            ├── ecr/
            ├── s3-artifacts/
            ├── lambda/
            └── api-gateway/   terragrunt.hcl   — the component
```

Each level owns a distinct class of decision, and `root.hcl` merges them into inputs every
component receives:

| Level | Owns | Examples |
|---|---|---|
| `namespace.hcl` | facts true of the application anywhere | owner, cost centre, ServiceAccount name, container port, registry repo name, secret path prefix |
| `environment.hcl` | tier-wide posture | `high_availability`, `deletion_protection`, backup and log retention, whether Spot is allowed, data classification |
| `account.hcl` | account identity and guardrails | account ID, assumed role, permissions boundary, state bucket suffix |
| `region.hcl` | placement | region, AZ list, replication region, primary-region flag |

Tier settings are what make the split worth having: `high_availability` alone drives multi-AZ
RDS, one NAT gateway per AZ, and cache replica placement — set once, not restated in every
leaf. Component names, tags and state keys derive from position in the tree, so moving a
directory moves its state.

Environments are separate AWS accounts, the only isolation boundary AWS enforces
unconditionally. A multi-tenant repository would usually carry a `tenant` level between
namespace and environment; omitted here — one application, one tenant.

## Components

| Stack | |
|---|---|
| `stack-network` | VPC, public and private subnets, NAT, interface endpoints |
| `stack-eks` | Control plane, managed node group, OIDC provider for IRSA |
| `stack-kubernetes-addons` | Load Balancer Controller, External Secrets Operator, external-dns, metrics-server |
| `stack-rds-postgres` | Managed PostgreSQL, password generated into Secrets Manager |
| `stack-valkey` | ElastiCache Valkey |
| `stack-ecr` | Image registry, immutable tags, lifecycle policy |
| `stack-s3` | Bucket with public access blocked, versioning, encryption, lifecycle |
| `stack-lambda` | Function, scoped execution role, explicit log group |
| `stack-api-gateway` | HTTP API, Lambda proxy integration, throttling |

`stack-kubernetes-addons` is separate from `stack-eks` so the cluster and the workloads inside
it have independent lifecycles, and so the `helm` and `kubernetes` providers are not configured
in the stack that creates the cluster they authenticate against.

## Secrets

No credential is stored in this repository, in Terraform state, or in a variable file.

RDS generates its master password directly into Secrets Manager. External Secrets Operator
runs in the cluster with an IRSA role scoped to the application's own secret path plus any
ARNs passed in explicitly, and materialises native Kubernetes Secrets from it. Workloads
consume those by name — the Helm chart's `secrets.existingSecret` is the seam for exactly
this — so the chart never holds the value.

The application ServiceAccount itself gets no IAM role: only the operator that needs AWS
access has one.

## Out of scope

- **DNS and certificates.** There is no hosted-zone or ACM stack, so `external-dns` is disabled
  in both environments — with no zone ARN the only alternative is an unscoped Route53 grant —
  and the API Gateway custom domain is left null, so the API answers on its generated
  `execute-api` hostname. Both become one input each once a certificate ARN and zone ID exist.
- **Deploying the application.** `documentation/03-cicd.md` describes the pipeline publishing a
  packaged chart and a GitOps controller reconciling it into the cluster. Installing that
  controller is not done here.
- **State backend bootstrapping.** The S3 bucket and lock table are referenced, not created.

## Running it

```bash
cd namespaces/podinfo/non-production/dev/us-east-1
terragrunt run-all plan          # whole environment
cd network && terragrunt apply   # one component
```

`run-all` orders components from the `dependency` blocks — network first, then eks, then the
stacks needing both. Mock outputs let `plan` run on a fresh checkout before anything exists;
they are restricted to read-only commands so an apply can never consume one.

## Known gaps

- **Never applied, and not validated by a tool.** `terraform`, `tofu` and `terragrunt` were not
  installed on the machine this was written on, so no `fmt`, `validate` or `hclfmt` has run
  against it. Structure was checked; semantics were not.
- **Chart and module versions are unverified.** The `chart_version` defaults in
  `stack-kubernetes-addons/variables.tf` and the `~>` module constraints were not checked
  against their registries.
- **`aws_account_id` is empty** in both `account.hcl` files, so the `allowed_account_ids`
  guard in `root.hcl` is commented out.
- **`.pre-commit-config.yaml` expects tooling this layout does not contain.** `hadolint`,
  `shellcheck` and `shfmt` match no files; `tofu_tflint` and `yamllint` fall back to built-in
  defaults because their config files are not present.
