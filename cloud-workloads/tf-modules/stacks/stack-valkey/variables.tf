variable "namespace" {
  description = "Application this belongs to."
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

variable "tags" {
  description = "Tags applied to every resource in this stack."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC to place the cluster in. Supplied by the network stack."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the cache nodes."
  type        = list(string)
}

variable "node_security_group_id" {
  description = "EKS node security group allowed to connect. Supplied by the eks stack."
  type        = string
}

variable "engine_version" {
  description = "Valkey engine version."
  type        = string
  default     = "7.2"
}

variable "parameter_group_name" {
  description = "Parameter group. Must match the engine major version."
  type        = string
  default     = "default.valkey7"
}

variable "node_type" {
  description = "Cache node instance type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "port" {
  description = "Listening port."
  type        = number
  default     = 6379
}

variable "high_availability" {
  description = "Inherited from the environment tier. Enables replicas, automatic failover and multi-AZ together."
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Read replicas, when high_availability is on."
  type        = number
  default     = 1
}

variable "transit_encryption_enabled" {
  description = "Require TLS from clients. Clients that do not speak TLS fail rather than degrade."
  type        = bool
  default     = false
}

variable "snapshot_retention_limit" {
  description = "Days of snapshots. Zero is defensible for a pure cache."
  type        = number
  default     = 0
}

variable "maintenance_window" {
  description = "Weekly window for engine patching, in UTC."
  type        = string
  default     = "sun:05:00-sun:06:00"
}
