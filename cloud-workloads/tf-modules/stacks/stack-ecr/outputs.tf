output "repository_url" {
  description = "Registry path. This is what image.repository becomes in the Helm chart on AWS."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "Repository ARN, for scoping the pipeline's push policy."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Repository name."
  value       = aws_ecr_repository.this.name
}
