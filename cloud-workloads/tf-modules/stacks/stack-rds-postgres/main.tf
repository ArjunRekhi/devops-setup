# Managed PostgreSQL. The local setup runs no database at all; this is what the
# component becomes on AWS, and the reason a StatefulSet in the cluster was not
# the answer: backups, point-in-time recovery, minor-version patching and
# cross-AZ failover are all somebody else's problem here.

locals {
  identifier = "${var.namespace}-${var.environment}-${var.stage}-postgres"

  tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  })
}

# Reachable only from the cluster nodes. No public accessibility, no CIDR
# allow-list -- membership of the node security group is the grant.
resource "aws_security_group" "this" {
  name        = "${local.identifier}-sg"
  description = "PostgreSQL access for the EKS nodes"
  vpc_id      = var.vpc_id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "from_nodes" {
  security_group_id            = aws_security_group.this.id
  description                  = "PostgreSQL from EKS nodes"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.node_security_group_id
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = local.identifier

  engine               = "postgres"
  engine_version       = var.engine_version
  family               = var.parameter_group_family
  major_engine_version = split(".", var.engine_version)[0]
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.master_username
  port     = 5432

  # No password anywhere in this repo, in Terraform state, or in a tfvars file.
  # RDS generates it, stores it in Secrets Manager encrypted with KMS, and
  # rotates it. External Secrets Operator then syncs it into the cluster as a
  # Kubernetes Secret, which the podinfo chart consumes via
  # `secrets.existingSecret` without ever holding the value itself.
  manage_master_user_password = true

  multi_az               = var.multi_az
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = !var.deletion_protection

  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = local.tags
}
