include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/lambda.hcl"
}

inputs = {
  function_purpose = "webhook"

  # CI writes the package here under a SHA-qualified key, so a deploy is
  # reproducible and a rollback is a key change rather than a rebuild.
  artifact_key = "webhook/latest.zip"

  memory_mb       = 512
  timeout_seconds = 20

  # Caps how hard a spike behind this function can hit the database.
  reserved_concurrency = 50
}
