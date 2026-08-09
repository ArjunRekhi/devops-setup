include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/api-gateway.hcl"
}

inputs = {
  # No custom_domain: it needs an ACM certificate ARN and a hosted zone ID, and
  # DNS is managed outside this repository. Until those are supplied the API is
  # reachable on its generated execute-api hostname.
  throttling_rate_limit  = 500
  throttling_burst_limit = 1000

  cors_allowed_origins = ["https://example.com"]
}
