# Component definition for the managed PostgreSQL instance.

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-rds-postgres"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id                     = "vpc-mock"
    database_subnet_group_name = "mock-subnet-group"
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
  db_subnet_group_name   = dependency.network.outputs.database_subnet_group_name
  node_security_group_id = dependency.eks.outputs.node_security_group_id

  engine_version         = "16.4"
  parameter_group_family = "postgres16"

  # Both follow the tier. deletion_protection arrives from root.hcl under the
  # same name, so it needs no mapping here.
  multi_az                = local.environment_vars.high_availability
  backup_retention_period = local.environment_vars.backup_retention_days
}
