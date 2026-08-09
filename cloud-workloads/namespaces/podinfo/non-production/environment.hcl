# Level 2 -- the environment tier.
#
# Tier-wide posture rather than per-component settings. Components read these
# through their tg-module, so "production is highly available" is stated once
# here instead of being re-decided in every leaf.

locals {
  environment = "nonprod"

  # Drives multi-AZ RDS, one NAT gateway per AZ, and Valkey replica placement.
  high_availability = false

  # Blocks `destroy` on anything holding data.
  deletion_protection = false

  # Automated backup and snapshot retention. Zero would disable point-in-time
  # recovery entirely.
  backup_retention_days = 3

  # CloudWatch log group retention. Never-expire is the AWS default and the
  # usual source of a surprise log bill.
  log_retention_days = 14

  # Spot is fine where interruption is a useful test of the PodDisruptionBudget,
  # and not fine where it is an incident.
  allow_spot_instances = true

  data_classification = "test"

  tags = {
    Environment = "nonprod"
    DataClass   = "test"
  }
}
