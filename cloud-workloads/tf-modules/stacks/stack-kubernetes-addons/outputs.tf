output "load_balancer_controller_role_arn" {
  description = "IRSA role assumed by the AWS Load Balancer Controller."
  value       = try(module.load_balancer_controller_irsa[0].iam_role_arn, null)
}

output "external_secrets_role_arn" {
  description = "IRSA role assumed by External Secrets Operator. The only identity permitted to read Secrets Manager."
  value       = try(module.external_secrets_irsa[0].iam_role_arn, null)
}

output "external_dns_role_arn" {
  description = "IRSA role assumed by external-dns."
  value       = try(module.external_dns_irsa[0].iam_role_arn, null)
}
