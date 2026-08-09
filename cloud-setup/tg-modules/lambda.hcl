# Component definition for the Lambda function.

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-lambda"
}

dependency "artifacts" {
  config_path = "../s3-artifacts"

  mock_outputs = {
    bucket_id = "mock-artifacts-bucket"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  # CI publishes the deployment package here; Terraform only references it.
  artifact_bucket = dependency.artifacts.outputs.bucket_id

  runtime = "provided.al2023"
  handler = "bootstrap"

  # log_retention_days arrives from root.hcl.
}
