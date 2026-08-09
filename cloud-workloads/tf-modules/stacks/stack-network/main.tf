# Network foundation: one VPC, public subnets for load balancers, private
# subnets for nodes and the database. Wraps the community VPC module rather
# than reimplementing subnets, route tables and NAT from first principles.

locals {
  name = "${var.namespace}-${var.environment}-${var.stage}"

  tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr
  azs  = var.availability_zones

  # /20 public, /20 private per AZ, carved out of the VPC CIDR so callers only
  # ever have to pick one range.
  public_subnets  = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnets = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  # The main cost-versus-resilience dial in this stack. One NAT gateway is
  # cheaper but becomes a single-AZ dependency for all egress; one per AZ
  # removes that at roughly the per-gateway hourly rate times the AZ count.
  enable_nat_gateway     = true
  single_nat_gateway     = !var.highly_available_nat
  one_nat_gateway_per_az = var.highly_available_nat

  enable_dns_hostnames = true
  enable_dns_support   = true

  # How the AWS Load Balancer Controller discovers where to place ALBs. Without
  # these tags an Ingress provisions nothing and fails silently.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}

# Keeps ECR pulls, S3 access and CloudWatch logs on the AWS backbone instead of
# routing them through the NAT gateway, which is billed per GB processed.
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = concat(
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids,
      )
    }
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }
    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }
  }

  tags = local.tags
}
