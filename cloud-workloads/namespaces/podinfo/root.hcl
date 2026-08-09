# Included by every leaf. Holds the two things that must be identical
# everywhere -- where state lives and how the AWS provider is configured -- and
# passes the hierarchy's locals down as inputs so no component has to
# rediscover where it is.

locals {
  namespace_vars   = read_terragrunt_config(find_in_parent_folders("namespace.hcl")).locals
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals

  namespace   = local.namespace_vars.namespace
  environment = local.environment_vars.environment
  stage       = local.account_vars.stage

  aws_account_id      = local.account_vars.aws_account_id
  aws_region          = local.region_vars.aws_region
  state_bucket_suffix = local.account_vars.state_bucket_suffix

  tags = merge(local.namespace_vars.tags, local.environment_vars.tags)
}

# Remote state, one object per component. The key is derived from the path, so
# the directory tree and the state layout cannot drift apart -- moving a
# directory moves its state.
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    # S3 bucket names are globally unique. The suffix comes from account.hcl; in
    # a real account it is usually the account ID.
    bucket = "${local.namespace}-tfstate-${local.state_bucket_suffix}-${local.aws_region}"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = local.aws_region

    encrypt = true

    # State locking. DynamoDB is the widely supported option; Terraform 1.10 and
    # OpenTofu 1.10 added native S3 locking (`use_lockfile = true`), which
    # removes the extra table. Pick one -- running both is redundant.
    dynamodb_table = "${local.namespace}-tflock-${local.state_bucket_suffix}"

    # Recovering from a bad apply means reading an older state object.
    versioning = true
  }
}

generate "provider_aws" {
  path      = "provider_aws.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"

      # Refuses to apply into the wrong account. Enable by setting
      # aws_account_id in the relevant account.hcl.
      # allowed_account_ids = ["${local.aws_account_id}"]

      default_tags {
        tags = {
          Namespace   = "${local.namespace}"
          Environment = "${local.environment}"
          Stage       = "${local.stage}"
          ManagedBy   = "terragrunt"
        }
      }
    }

    # Secondary provider for cross-region replicas: KMS multi-region keys, S3
    # replication targets, ACM certificates for edge-optimised endpoints.
    provider "aws" {
      alias  = "replica"
      region = "${local.region_vars.replication_region}"
    }
  EOF
}

# Passed to every component. Terragrunt exports these as TF_VAR_ variables, so a
# stack that does not declare one simply ignores it.
inputs = {
  # Identity -- where this component sits in the hierarchy.
  namespace   = local.namespace
  environment = local.environment
  stage       = local.stage
  region      = local.aws_region
  tags        = local.tags

  # Application facts (namespace.hcl)
  kubernetes_namespace = local.namespace_vars.kubernetes_namespace
  service_account_name = local.namespace_vars.service_account_name
  container_port       = local.namespace_vars.container_port
  ecr_repository_name  = local.namespace_vars.ecr_repository_name
  secret_path_prefix   = local.namespace_vars.secret_path_prefix

  # Tier posture (environment.hcl) -- components turn these into concrete
  # settings, so "production is highly available" is stated once.
  high_availability     = local.environment_vars.high_availability
  deletion_protection   = local.environment_vars.deletion_protection
  backup_retention_days = local.environment_vars.backup_retention_days
  log_retention_days    = local.environment_vars.log_retention_days
  allow_spot_instances  = local.environment_vars.allow_spot_instances
  data_classification   = local.environment_vars.data_classification

  # Account (account.hcl)
  permissions_boundary_name = local.account_vars.permissions_boundary_name

  # Placement (region.hcl)
  availability_zones = local.region_vars.availability_zones
  replication_region = local.region_vars.replication_region
  is_primary_region  = local.region_vars.is_primary_region
}
