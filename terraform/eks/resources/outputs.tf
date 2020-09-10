output "kubeconfig" {
  value = module.eks.kubeconfig
}

output "aws_region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}
