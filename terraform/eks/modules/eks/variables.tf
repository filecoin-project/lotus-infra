variable "prefix" {
  description = "Prefix name to tag resources with"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for eks cluster"
}

variable "region" {
  description = "AWS region e.g. us-east-1"
  type        = string
  default     = "us-east-2"
}

variable "public_subnets" {
  description = "Public Subnets for EKS control plane"
}

variable "private_subnets" {
  description = "Private Subnets for EKS control plane"
}

variable "security_group_ids" {
  description = "Security group ids for EKS"
  type        = list
}

variable "eks_iam_usernames" {
  description = "List of IAM usernames to grant EKS access"
  type        = list(string)

  default = [
    "marcus",
    "travisperson",
    "cory",
    "mg",
    "frrst",
    "iand",
    "lanzafame",
    "hannah.howard",
    "raulK",
    "willscott",
  ]
}

variable "kubeconfig_aws_authenticator_env_variables" {
  description = "Maps to the Terraform EKS module of the same name"
  default     = {}
}

variable "aws_profile" {
  description = "AWS Profile to use when applicable"
}

variable "k8s_worker_count" {
  default = 3
}

variable "k8s_version" {
  description = "The Kubernetes version to install in EKS"
  default     = "1.17"
}

variable "key_name" {
  description = "EC2 SSH key name to set for autoscaling group instances"
  default     = "filecoin"
}

variable "external_dns_fqdn" {
  description = "the domain to configure external-dns deployment in kubernetes with"
  default     = "kittyhawk.wtf"
}

variable "external_dns_zone_id" {
  description = "the DNS Zone ID to give external-dns access to"
  default     = "Z4QUK41V3HPV5"
}

variable "worker_count_open" {
  description = "k8s worker count that have open networking permissions"
  default     = 5
}

variable "worker_count_restricted" {
  description = "k8s worker count that have restricted networking permissions"
  default     = 5
}

variable "node_groups" {
  description = "autoscaling group for kubernetes worker"
  default     = [{}]
}

variable "acm_enabled" {
  description = "generate ACM cerificate for external DNS? only required if wanting HTTPS"
  default     = 0
}
