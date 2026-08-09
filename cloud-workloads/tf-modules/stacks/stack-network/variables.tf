variable "namespace" {
  description = "Application this infrastructure belongs to."
  type        = string
}

variable "environment" {
  description = "Environment tier, e.g. nonprod or prod."
  type        = string
}

variable "stage" {
  description = "Account-level stage within the environment, e.g. dev or prod."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must not overlap any peered network."
  type        = string
}

variable "availability_zones" {
  description = "AZs to spread subnets across. Two is the practical minimum for EKS."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "EKS requires subnets in at least two availability zones."
  }
}

variable "highly_available_nat" {
  description = "One NAT gateway per AZ instead of a single shared one. Costs more; removes a single-AZ egress dependency."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource in this stack."
  type        = map(string)
  default     = {}
}
