# Component definition for the EKS cluster.

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-eks"
}

dependency "network" {
  config_path = "../network"

  # Mocks let `plan` and `validate` run before the network exists, which is what
  # makes a whole-tree `terragrunt run-all plan` work on a fresh checkout.
  # Restricted to read-only commands so an apply can never consume a fake value,
  # and written to be obviously fake so one is never mistaken for real.
  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
    public_subnet_ids  = ["subnet-mock-c", "subnet-mock-d"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids

  # Pinned deliberately. EKS trails upstream Kubernetes and supports a fixed
  # window of versions; upgrading is a decision, not a side effect of an apply.
  cluster_version = "1.31"

  # Spot where the tier permits it. Reclamation is a useful, free test of the
  # workload PodDisruptionBudget; in production it is an incident.
  node_capacity_type = local.environment_vars.allow_spot_instances ? "SPOT" : "ON_DEMAND"

  # Private API endpoint in every tier, so the access path production uses is
  # the one exercised daily. Reaching the API server means a VPN or a bastion.
  cluster_endpoint_public_access = false
}
