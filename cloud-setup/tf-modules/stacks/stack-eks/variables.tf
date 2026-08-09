variable "namespace" {
  description = "Application this cluster belongs to."
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
  description = "VPC to place the cluster in. Supplied by the network stack."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the control plane ENIs and the nodes."
  type        = list(string)
}

variable "cluster_version" {
  description = "Kubernetes minor version. EKS trails upstream, so pin it and upgrade deliberately."
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Expose the API server endpoint publicly. Keep false unless something outside the VPC needs it."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Source CIDRs allowed to reach a public API endpoint. Never leave this at 0.0.0.0/0."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_min_size" {
  description = "Minimum nodes."
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum nodes. Must leave headroom above the workload HPA maximum."
  type        = number
  default     = 4
}

variable "node_group_desired_size" {
  description = "Starting node count. Ignored on subsequent applies once the autoscaler owns it."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to every resource in this stack."
  type        = map(string)
  default     = {}
}
