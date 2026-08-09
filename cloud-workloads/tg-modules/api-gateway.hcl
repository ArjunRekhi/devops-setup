# Component definition for the HTTP API.

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-api-gateway"
}

dependency "lambda" {
  config_path = "../lambda"

  mock_outputs = {
    invoke_arn    = "arn:aws:apigateway:mock:lambda:path/mock"
    function_name = "mock-function"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  lambda_invoke_arn    = dependency.lambda.outputs.invoke_arn
  lambda_function_name = dependency.lambda.outputs.function_name

  # Shorter than the Lambda timeout, so the client is never told a request
  # failed while the function is still running and still being billed.
  integration_timeout_ms = 29000

  # log_retention_days arrives from root.hcl.
}
