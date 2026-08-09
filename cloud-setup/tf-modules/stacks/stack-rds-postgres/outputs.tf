output "endpoint" {
  description = "Connection endpoint. Goes into the application ConfigMap, not the Secret -- a hostname is not sensitive."
  value       = module.db.db_instance_endpoint
}

output "port" {
  description = "Listening port."
  value       = module.db.db_instance_port
}

output "database_name" {
  description = "Initial database name."
  value       = module.db.db_instance_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN holding the generated master password. Grant this to the External Secrets Operator role, and nothing wider."
  value       = try(module.db.db_instance_master_user_secret_arn, null)
}

output "security_group_id" {
  description = "Security group guarding the instance."
  value       = aws_security_group.this.id
}
