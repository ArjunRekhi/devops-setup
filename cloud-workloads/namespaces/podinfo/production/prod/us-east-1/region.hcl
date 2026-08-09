# Level 4 -- the region.
#
# A second region is a sibling directory with the same components underneath it.

locals {
  aws_region = "us-east-1"

  # Availability zones for everything in this region. Set here rather than per
  # component so the VPC, the node group and the database cannot end up spread
  # across different AZ sets.
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Where cross-region backups and multi-region KMS replicas land. Must differ
  # from aws_region or it is not a disaster recovery story.
  replication_region = "us-west-2"

  # Only the primary region owns the Route53 hosted zone and the ECR repository.
  is_primary_region = true
}
