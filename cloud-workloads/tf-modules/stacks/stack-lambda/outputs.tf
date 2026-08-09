output "function_name" {
  description = "Function name."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Function ARN."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "ARN in the form API Gateway integrations require. Not interchangeable with function_arn."
  value       = aws_lambda_function.this.invoke_arn
}

output "role_arn" {
  description = "Execution role ARN, for granting the function access to other resources."
  value       = aws_iam_role.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}
