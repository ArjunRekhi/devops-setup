include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/ecr.hcl"
}

inputs = {
  tagged_image_retention_count = 30
}
