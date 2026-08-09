include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/eks.hcl"
}

inputs = {
  node_instance_types = ["m6i.large"]

  # Headroom above the workload HPA ceiling (maxReplicas 6 in the podinfo
  # chart). An HPA that cannot get nodes is an HPA that does nothing.
  node_group_min_size     = 3
  node_group_max_size     = 8
  node_group_desired_size = 3
}
