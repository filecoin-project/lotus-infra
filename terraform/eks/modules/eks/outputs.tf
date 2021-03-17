output "kubeconfig" {
  value = module.eks.kubeconfig
}

output "cluster_id" {
  value = module.eks.cluster_id
}
