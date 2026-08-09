include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/eks.hcl"
}

inputs = {
  node_instance_types = ["t3.medium"]

  node_group_min_size     = 2
  node_group_max_size     = 4
  node_group_desired_size = 2
}
