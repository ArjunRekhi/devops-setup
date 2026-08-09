output "primary_endpoint" {
  description = "Write endpoint. This is what podinfo's --cache-server flag would point at."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Read endpoint, load-balanced across replicas. Null when high_availability is off."
  value       = try(aws_elasticache_replication_group.this.reader_endpoint_address, null)
}

output "port" {
  description = "Listening port."
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "Security group guarding the cluster."
  value       = aws_security_group.this.id
}
