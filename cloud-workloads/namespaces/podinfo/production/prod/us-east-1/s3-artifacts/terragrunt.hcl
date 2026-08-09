include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/s3.hcl"
}

inputs = {
  bucket_purpose = "artifacts"

  # Build artefacts are read once at deploy time and after that only for
  # rollback, so they are worth moving off standard storage.
  transition_to_ia_days             = 30
  noncurrent_version_retention_days = 90
}
