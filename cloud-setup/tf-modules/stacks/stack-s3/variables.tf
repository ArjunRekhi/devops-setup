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

variable "bucket_purpose" {
  description = "What the bucket is for. Becomes part of the globally unique name."
  type        = string
}

variable "data_classification" {
  description = "Inherited from the environment tier. Tagged so data-handling policy can be audited."
  type        = string
  default     = "test"
}

variable "versioning_enabled" {
  description = "Keep previous object versions. Required for replication and for recovering an overwrite."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Customer-managed key. Null uses SSE-S3, which is free and adequate for non-sensitive data."
  type        = string
  default     = null
}

variable "noncurrent_version_retention_days" {
  description = "How long superseded versions are kept before expiry."
  type        = number
  default     = 30
}

variable "transition_to_ia_days" {
  description = "Move objects to Standard-IA after this many days. Null disables the transition."
  type        = number
  default     = null
}

variable "deletion_protection" {
  description = "Refuse to empty the bucket in order to destroy it."
  type        = bool
  default     = false
}
