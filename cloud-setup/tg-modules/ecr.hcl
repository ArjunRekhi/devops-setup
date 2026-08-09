# Component definition for the container registry.
#
# No dependencies -- the registry exists before anything that pulls from it, and
# the CI pipeline pushes to it without touching the cluster at all.

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-ecr"
}

inputs = {
  # Immutable everywhere. A movable tag makes `helm rollback` meaningless, which
  # is the same reason the chart never uses :latest.
  image_tag_mutability = "IMMUTABLE"

  # ecr_repository_name and deletion_protection arrive from root.hcl.
}
