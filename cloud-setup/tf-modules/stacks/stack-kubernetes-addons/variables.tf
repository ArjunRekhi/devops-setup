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

variable "cluster_name" {
  description = "EKS cluster name. Supplied by the eks stack."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API server endpoint. Supplied by the eks stack."
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 CA certificate for the API server. Supplied by the eks stack."
  type        = string
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for IRSA. Supplied by the eks stack."
  type        = string
}

variable "secret_path_prefix" {
  description = "Secrets Manager path this application owns. Scopes the External Secrets Operator grant to a prefix instead of a wildcard."
  type        = string
}

# Every addon carries its own toggle so an environment can run a subset, and so
# a broken chart can be switched off without deleting its configuration.

variable "load_balancer_controller" {
  description = "AWS Load Balancer Controller. Required for Ingress to produce an ALB."
  type = object({
    enabled       = bool
    chart_version = string
  })
  default = {
    enabled       = true
    chart_version = "1.8.1"
  }
}

variable "external_secrets" {
  description = "External Secrets Operator, plus the Secrets Manager and KMS ARNs its IAM role may read."
  type = object({
    enabled              = bool
    chart_version        = string
    secrets_manager_arns = list(string)
    kms_key_arns         = list(string)
  })
  default = {
    enabled              = true
    chart_version        = "0.9.20"
    secrets_manager_arns = []
    kms_key_arns         = []
  }
}

variable "external_dns" {
  description = "external-dns, plus the hosted zones its IAM role may write to."
  type = object({
    enabled          = bool
    chart_version    = string
    domain_filter    = string
    hosted_zone_arns = list(string)
  })
  default = {
    enabled          = false
    chart_version    = "1.14.5"
    domain_filter    = ""
    hosted_zone_arns = []
  }
}

variable "metrics_server" {
  description = "metrics-server. Not preinstalled on EKS; the workload HPA does not function without it."
  type = object({
    enabled       = bool
    chart_version = string
  })
  default = {
    enabled       = true
    chart_version = "3.12.1"
  }
}

variable "tags" {
  description = "Tags applied to every resource in this stack."
  type        = map(string)
  default     = {}
}
