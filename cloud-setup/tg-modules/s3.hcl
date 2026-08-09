# Component definition for an S3 bucket.
#
# bucket_purpose is set per leaf, because one environment usually wants more
# than one bucket and they differ only by purpose.

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../../tf-modules//stacks/stack-s3"
}

inputs = {
  versioning_enabled = true

  # data_classification and deletion_protection arrive from root.hcl.
}
