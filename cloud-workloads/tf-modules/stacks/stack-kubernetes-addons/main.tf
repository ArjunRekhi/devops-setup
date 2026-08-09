# Cluster-level components that every workload depends on but no workload owns.
#
# Split out of stack-eks on purpose. The control plane and the things running
# inside it have different lifecycles and different blast radii: upgrading a
# Helm chart should never be able to touch control-plane state, and a failed
# addon apply should not leave the cluster itself half-modified. It also keeps
# the helm and kubernetes providers out of the stack that creates the cluster
# they authenticate against, which is the usual chicken-and-egg failure.
#
# Application workloads are NOT here. podinfo ships as its own Helm chart in
# kubernetes-application/charts/podinfo-app and is deployed by the pipeline, not by
# Terraform -- see documentation/03-cicd.md.

data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  })

  # Every secret this application owns lives under one path, so the grant is a
  # prefix rather than a list that has to be edited each time a key is added.
  # Composed from the caller's own account, so no account ID is written down.
  application_secret_arn = format(
    "arn:aws:secretsmanager:%s:%s:secret:%s/*",
    var.region,
    data.aws_caller_identity.current.account_id,
    var.secret_path_prefix,
  )
}

# ---------------------------------------------------------------------------
# AWS Load Balancer Controller
#
# Turns an Ingress into a real ALB. This is the AWS counterpart to the
# ingress-nginx addon used on minikube: TLS terminates at the ALB with an ACM
# certificate instead of a TLS Secret held in the cluster.
# ---------------------------------------------------------------------------

module "load_balancer_controller_irsa" {
  count = var.load_balancer_controller.enabled ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "${var.cluster_name}-aws-lbc"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

resource "helm_release" "load_balancer_controller" {
  count = var.load_balancer_controller.enabled ? 1 : 0

  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.load_balancer_controller.chart_version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.load_balancer_controller_irsa[0].iam_role_arn
  }
}

# ---------------------------------------------------------------------------
# External Secrets Operator
#
# The answer to "how do secrets reach pods on EKS". ESO reads from AWS Secrets
# Manager and materialises a native Kubernetes Secret, which is why the podinfo
# chart exposes `secrets.existingSecret`: with ESO in place the chart renders no
# Secret of its own and simply consumes one it does not own.
#
# Only this operator holds the IAM permission to read Secrets Manager. The
# application ServiceAccount has no AWS identity at all.
# ---------------------------------------------------------------------------

module "external_secrets_irsa" {
  count = var.external_secrets.enabled ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                      = "${var.cluster_name}-external-secrets"
  attach_external_secrets_policy = true

  # This application's own secret path, plus anything passed in explicitly --
  # the RDS-managed master password, which lives outside that path because RDS
  # names it. Never a bare wildcard: that would hand every credential in the
  # account to any namespace able to create an ExternalSecret.
  external_secrets_secrets_manager_arns = concat(
    [local.application_secret_arn],
    var.external_secrets.secrets_manager_arns,
  )
  external_secrets_kms_key_arns = var.external_secrets.kms_key_arns

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = local.tags
}

resource "helm_release" "external_secrets" {
  count = var.external_secrets.enabled ? 1 : 0

  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets.chart_version

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_secrets_irsa[0].iam_role_arn
  }
}

# ---------------------------------------------------------------------------
# external-dns
#
# Creates the Route53 record for the Ingress host. Locally this is a line in
# /etc/hosts; here it is a controller with a scoped IAM role.
# ---------------------------------------------------------------------------

module "external_dns_irsa" {
  count = var.external_dns.enabled ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                  = "${var.cluster_name}-external-dns"
  attach_external_dns_policy = true

  # Limited to the zones this application owns.
  external_dns_hosted_zone_arns = var.external_dns.hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = local.tags
}

resource "helm_release" "external_dns" {
  count = var.external_dns.enabled ? 1 : 0

  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = var.external_dns.chart_version

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_dns_irsa[0].iam_role_arn
  }

  set {
    name  = "domainFilters[0]"
    value = var.external_dns.domain_filter
  }
}

# ---------------------------------------------------------------------------
# metrics-server
#
# Not installed by EKS. Without it the podinfo chart's HorizontalPodAutoscaler
# reports TARGETS <unknown> and never scales -- the same reason the local
# minikube script enables the metrics-server addon.
# ---------------------------------------------------------------------------

resource "helm_release" "metrics_server" {
  count = var.metrics_server.enabled ? 1 : 0

  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = var.metrics_server.chart_version
}
