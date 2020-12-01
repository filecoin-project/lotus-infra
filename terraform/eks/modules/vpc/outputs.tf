output "aws_region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "security_group_ids" {
  value = [aws_security_group.efs.id]
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}
