include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/rds-postgres.hcl"
}

inputs = {
  instance_class = "db.m6g.large"

  allocated_storage     = 100
  max_allocated_storage = 500
}
