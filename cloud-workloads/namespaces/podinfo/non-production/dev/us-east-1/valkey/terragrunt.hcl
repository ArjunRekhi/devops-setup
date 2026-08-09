include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/valkey.hcl"
}

inputs = {
  node_type     = "cache.t4g.micro"
  replica_count = 0

  transit_encryption_enabled = false
  snapshot_retention_limit   = 0
}
