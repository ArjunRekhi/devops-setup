# Component definition for the Valkey cache.

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-valkey"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    node_security_group_id = "sg-mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  vpc_id                 = dependency.network.outputs.vpc_id
  private_subnet_ids     = dependency.network.outputs.private_subnet_ids
  node_security_group_id = dependency.eks.outputs.node_security_group_id

  engine_version       = "7.2"
  parameter_group_name = "default.valkey7"

  # high_availability arrives from root.hcl and drives replicas, automatic
  # failover and multi-AZ together.
}
