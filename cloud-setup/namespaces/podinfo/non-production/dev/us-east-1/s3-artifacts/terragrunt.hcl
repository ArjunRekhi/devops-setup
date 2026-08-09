include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/s3.hcl"
}

inputs = {
  bucket_purpose = "artifacts"

  noncurrent_version_retention_days = 14
}
