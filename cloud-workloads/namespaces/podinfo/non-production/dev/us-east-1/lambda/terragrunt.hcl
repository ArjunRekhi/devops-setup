include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/lambda.hcl"
}

inputs = {
  function_purpose = "webhook"
  artifact_key     = "webhook/latest.zip"

  memory_mb       = 256
  timeout_seconds = 10
}
