include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/../../tg-modules/rds-postgres.hcl"
}

inputs = {
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 50
}
