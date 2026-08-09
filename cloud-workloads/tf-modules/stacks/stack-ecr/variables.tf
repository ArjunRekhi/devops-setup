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

variable "ecr_repository_name" {
  description = "Repository name within the namespace."
  type        = string
}

variable "image_tag_mutability" {
  description = "IMMUTABLE stops a tag being repointed. MUTABLE only where a floating tag is genuinely wanted."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be IMMUTABLE or MUTABLE."
  }
}

variable "kms_key_arn" {
  description = "Customer-managed key for image encryption. Null uses the AES256 default, which is free."
  type        = string
  default     = null
}

variable "tagged_image_retention_count" {
  description = "How many SHA-tagged images to keep. Must exceed how far back a rollback might reach."
  type        = number
  default     = 30
}

variable "pull_account_ids" {
  description = "Other AWS accounts permitted to pull. Empty keeps the repository private to this account."
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "Refuse to delete a repository that still holds images."
  type        = bool
  default     = false
}
