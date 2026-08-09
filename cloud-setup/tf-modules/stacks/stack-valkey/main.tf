# Valkey on ElastiCache -- the cache tier.
#
# podinfo takes a `--cache-server` flag and speaks the Redis protocol, which
# Valkey is wire-compatible with, so this is the one optional AWS component the
# application could genuinely use rather than merely sit next to.
#
# Same argument as the database for why it is managed and not a StatefulSet:
# failover, patching and backups are the entire product.

locals {
  name = "${var.namespace}-${var.environment}-${var.stage}-valkey"

  tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  })
}

resource "aws_elasticache_subnet_group" "this" {
  name       = local.name
  subnet_ids = var.private_subnet_ids

  tags = local.tags
}

# Reachable from the cluster nodes and nothing else. Membership of the node
# security group is the grant; there is no CIDR allow-list to get wrong.
resource "aws_security_group" "this" {
  name        = "${local.name}-sg"
  description = "Valkey access for the EKS nodes"
  vpc_id      = var.vpc_id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "from_nodes" {
  security_group_id            = aws_security_group.this.id
  description                  = "Valkey from EKS nodes"
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.node_security_group_id
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.name
  description          = "${var.namespace} ${var.environment} cache"

  engine         = "valkey"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = var.port

  parameter_group_name = var.parameter_group_name

  # One node per replica plus the primary. Automatic failover needs at least
  # two, and multi-AZ needs automatic failover -- they are not independent
  # switches, so both follow the tier's high_availability setting.
  num_cache_clusters         = var.high_availability ? var.replica_count + 1 : 1
  automatic_failover_enabled = var.high_availability
  multi_az_enabled           = var.high_availability

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  at_rest_encryption_enabled = true

  # In-transit encryption means clients must speak TLS. Worth knowing before
  # enabling it: a client configured for plaintext fails to connect rather than
  # falling back, and podinfo's --cache-server takes a plain tcp:// URL.
  transit_encryption_enabled = var.transit_encryption_enabled

  # A cache is not a database. Snapshots exist so a cold start does not stampede
  # the origin, not as a recovery point -- everything here is reconstructible.
  snapshot_retention_limit = var.snapshot_retention_limit

  # Applied in the next maintenance window rather than immediately, because
  # apply_immediately on a replication group is a failover.
  apply_immediately          = false
  auto_minor_version_upgrade = true
  maintenance_window         = var.maintenance_window

  tags = local.tags
}
