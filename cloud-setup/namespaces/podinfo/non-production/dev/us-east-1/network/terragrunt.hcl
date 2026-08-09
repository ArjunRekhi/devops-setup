include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/network.hcl"
}

inputs = {
  vpc_cidr = "10.20.0.0/16"
}
