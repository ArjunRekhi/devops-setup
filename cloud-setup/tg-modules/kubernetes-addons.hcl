# Component definition for the cluster addons.

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-kubernetes-addons"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name                       = "mock-cluster"
    cluster_endpoint                   = "https://mock.invalid"
    cluster_certificate_authority_data = "bW9jaw=="
    oidc_provider_arn                  = "arn:aws:iam::mock:oidc-provider/mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  cluster_name                       = dependency.eks.outputs.cluster_name
  cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data
  oidc_provider_arn                  = dependency.eks.outputs.oidc_provider_arn
}
