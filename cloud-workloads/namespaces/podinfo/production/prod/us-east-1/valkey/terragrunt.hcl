include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/valkey.hcl"
}

inputs = {
  node_type     = "cache.m7g.large"
  replica_count = 2

  # Clients must speak TLS once this is on. Anything pointed at this cache with
  # a plain tcp:// URL fails to connect rather than falling back.
  transit_encryption_enabled = true

  # A cache is reconstructible, but a cold start after an incident stampedes the
  # database. One day of snapshots buys a warm restart.
  snapshot_retention_limit = 1
}
