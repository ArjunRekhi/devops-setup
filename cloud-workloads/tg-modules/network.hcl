# Component definition for the network stack: which Terraform to run, and the
# inputs that are the same in every environment. Only genuinely per-environment
# values are left to the leaf.

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-network"
}

inputs = {
  # NAT redundancy follows the tier's posture rather than being re-decided in
  # each leaf. availability_zones arrives from region.hcl via root.hcl.
  highly_available_nat = local.environment_vars.high_availability
}
