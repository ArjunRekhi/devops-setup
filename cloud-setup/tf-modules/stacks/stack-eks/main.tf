# EKS control plane and managed node groups. Deliberately contains no workloads
# and no Helm releases -- see stack-kubernetes-addons for why.

locals {
  cluster_name = "${var.namespace}-${var.environment}-${var.stage}"

  tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  })
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Private-only endpoint is the right default; public access is opt-in and,
  # when enabled, should always be CIDR-restricted rather than left at 0.0.0.0/0.
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # OIDC provider for the cluster. This is what makes IRSA possible at all --
  # without it, pods fall back to the node instance role and every workload on
  # the node shares one identity.
  enable_irsa = true

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    default = {
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type
    }
  }

  # Control-plane logs are off by default and cannot be enabled retroactively
  # for events that already happened.
  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  tags = local.tags
}
