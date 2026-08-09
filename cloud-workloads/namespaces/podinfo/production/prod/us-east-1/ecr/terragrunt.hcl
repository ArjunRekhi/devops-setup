include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/ecr.hcl"
}

inputs = {
  # Deep enough that a rollback can reach any image still plausibly running.
  tagged_image_retention_count = 100
}
