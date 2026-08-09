# Level 3 -- the AWS account.
#
# Environments live in separate accounts. That is the only isolation boundary
# AWS enforces without exception: a runaway apply in dev cannot reach
# another account whatever the IAM policy says.

locals {
  stage = "dev"

  # 12-digit AWS account ID. Deliberately empty -- nothing here has ever been
  # applied and this repository carries no real account identifiers. Filling it
  # in activates the allowed_account_ids guard in root.hcl.
  aws_account_id = ""

  # Role Terragrunt assumes to manage this account. Empty means "use whatever
  # credentials the caller already has", which is fine locally and wrong in CI.
  terraform_role_name = "TerraformExecution"

  # Attached to every IAM role this repository creates. A permissions boundary
  # caps what a role can be granted, so an over-broad policy document cannot
  # exceed it. Empty until the boundary exists in the account.
  permissions_boundary_name = ""

  # Suffix for the state bucket. S3 bucket names are globally unique, so in a
  # real account this is usually the account ID.
  state_bucket_suffix = "dev"
}
