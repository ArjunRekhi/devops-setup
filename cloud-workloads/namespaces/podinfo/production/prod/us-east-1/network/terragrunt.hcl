include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/network.hcl"
}

inputs = {
  # Non-overlapping with the other environment, so the two could ever be
  # peered. AZ count and NAT redundancy come from region.hcl and the tier.
  vpc_cidr = "10.10.0.0/16"
}
