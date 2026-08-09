output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA certificate for the API server."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "Kubernetes version actually running."
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN. Every IRSA trust policy references this."
  value       = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  description = "Security group attached to the nodes. Databases grant ingress to this."
  value       = module.eks.node_security_group_id
}
