output "bucket_id" {
  description = "Bucket name."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Bucket ARN, for scoping IAM policies to this bucket alone."
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Regional endpoint. Prefer this over the global name to avoid a cross-region redirect."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
