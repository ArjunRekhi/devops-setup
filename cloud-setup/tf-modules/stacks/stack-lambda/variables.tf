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

variable "function_purpose" {
  description = "What the function does. Becomes part of its name."
  type        = string
}

variable "artifact_bucket" {
  description = "S3 bucket holding the deployment package, published by CI."
  type        = string
}

variable "artifact_key" {
  description = "S3 key of the deployment package. Version or SHA-qualified so a deploy is reproducible."
  type        = string
}

variable "artifact_source_code_hash" {
  description = "Base64 SHA256 of the package. Without it Terraform cannot tell that the code changed."
  type        = string
  default     = null
}

variable "handler" {
  description = "Entry point."
  type        = string
  default     = "bootstrap"
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "provided.al2023"
}

variable "timeout_seconds" {
  description = "Maximum execution time. Must exceed the API Gateway integration timeout or the caller gives up first."
  type        = number
  default     = 10
}

variable "memory_mb" {
  description = "Memory, which also determines the CPU share. More memory is often cheaper per request, not dearer."
  type        = number
  default     = 256
}

variable "reserved_concurrency" {
  description = "Concurrency cap. -1 leaves the function sharing the account pool with everything else."
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "Plain configuration only. Secrets belong in Secrets Manager and are fetched at runtime."
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "Attach to the VPC, needed only to reach private resources. Costs cold-start time, so null by default."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "log_retention_days" {
  description = "Inherited from the environment tier."
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "Customer-managed key for log encryption. Null uses the CloudWatch default."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Boundary attached to the execution role. Caps what the role can ever be granted."
  type        = string
  default     = null
}
