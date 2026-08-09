include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/api-gateway.hcl"
}

inputs = {
  throttling_rate_limit  = 50
  throttling_burst_limit = 100

  # Any origin, because non-production is called from local development.
  cors_allowed_origins = ["*"]
}
