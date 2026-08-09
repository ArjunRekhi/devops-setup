include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/kubernetes-addons.hcl"
}

dependency "rds" {
  config_path = "../rds-postgres"

  mock_outputs = {
    master_user_secret_arn = "arn:aws:secretsmanager:mock:secret:mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  # The IAM grant is scoped to the application's own Secrets Manager path plus
  # exactly one extra ARN: the RDS-managed master password. A wildcard would let
  # anyone able to create an ExternalSecret read every secret in the account.
  external_secrets = {
    enabled              = true
    chart_version        = "0.9.20"
    secrets_manager_arns = [dependency.rds.outputs.master_user_secret_arn]
    kms_key_arns         = []
  }

  # Off. The hosted zone and its certificate are managed outside this
  # repository, so there is no zone ARN to scope the controller's IAM role to,
  # and external-dns with an unscoped Route53 grant is worse than no
  # external-dns. Reach the ALB by its generated hostname until that changes.
  external_dns = {
    enabled          = false
    chart_version    = "1.14.5"
    domain_filter    = ""
    hosted_zone_arns = []
  }
}
