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

variable "lambda_invoke_arn" {
  description = "Lambda invoke ARN. Supplied by the lambda stack; not the same as the function ARN."
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name, for the invoke permission."
  type        = string
}

variable "route_key" {
  description = "Route to match. `$default` catches everything and lets the function route internally."
  type        = string
  default     = "$default"
}

variable "integration_timeout_ms" {
  description = "Integration timeout. Keep below the Lambda timeout or the client is told it failed while it is still running."
  type        = number
  default     = 29000
}

variable "throttling_burst_limit" {
  description = "Burst capacity before requests are rejected with 429."
  type        = number
  default     = 100
}

variable "throttling_rate_limit" {
  description = "Steady-state requests per second."
  type        = number
  default     = 50
}

variable "cors_allowed_origins" {
  description = "Origins permitted to call the API from a browser. Null disables CORS entirely."
  type        = list(string)
  default     = null
}

variable "jwt_authorizer" {
  description = "Validate a JWT at the edge so unauthenticated requests never reach the function. Null leaves the route open."
  type = object({
    issuer   = string
    audience = list(string)
  })
  default = null
}

variable "custom_domain" {
  description = "Stable hostname, its ACM certificate and hosted zone. DNS is managed outside this repository, so this is null by default and the generated execute-api name is used."
  type = object({
    domain_name     = string
    certificate_arn = string
    zone_id         = string
  })
  default = null
}

variable "log_retention_days" {
  description = "Inherited from the environment tier."
  type        = number
  default     = 14
}
