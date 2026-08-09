variable "namespace" {
  description = "Application this database belongs to."
  type        = string
}

variable "environment" {
  description = "Environment tier, e.g. nonprod or prod."
  type        = string
}

variable "stage" {
  description = "Account-level stage within the environment."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC to place the instance in. Supplied by the network stack."
  type        = string
}

variable "db_subnet_group_name" {
  description = "Subnet group spanning the private subnets. Supplied by the network stack."
  type        = string
}

variable "node_security_group_id" {
  description = "EKS node security group allowed to connect. Supplied by the eks stack."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL version. Pinned; RDS will not upgrade a major version on its own."
  type        = string
  default     = "16.4"
}

variable "parameter_group_family" {
  description = "Parameter group family, must match the engine major version."
  type        = string
  default     = "postgres16"
}

variable "instance_class" {
  description = "Instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Ceiling for storage autoscaling. Set above allocated_storage to enable it."
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Initial database name."
  type        = string
  default     = "podinfo"
}

variable "master_username" {
  description = "Master username. The password is generated and held in Secrets Manager, never here."
  type        = string
  default     = "podinfo"
}

variable "multi_az" {
  description = "Synchronous standby in a second AZ. The difference between a failover and an outage."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days of automated backups. Zero disables point-in-time recovery entirely."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Block deletion, and take a final snapshot when deletion is eventually allowed."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource in this stack."
  type        = map(string)
  default     = {}
}
