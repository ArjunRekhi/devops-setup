output "api_id" {
  description = "API identifier."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Generated execute-api endpoint. Superseded by the custom domain when one is configured."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "custom_domain_name" {
  description = "Custom hostname, when one is configured."
  value       = try(aws_apigatewayv2_domain_name.this[0].domain_name, null)
}

output "execution_arn" {
  description = "Execution ARN, used to scope invoke permissions to this API."
  value       = aws_apigatewayv2_api.this.execution_arn
}
