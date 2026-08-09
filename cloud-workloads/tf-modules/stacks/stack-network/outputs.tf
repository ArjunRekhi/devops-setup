output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnets, for nodes and the database."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnets, for internet-facing load balancers."
  value       = module.vpc.public_subnets
}

output "database_subnet_group_name" {
  description = "Subnet group name for RDS. Uses the private subnets."
  value       = module.vpc.database_subnet_group_name
}
