variable "prefix" {
  description = "Prefix name to tag resources with"
  type        = string
}

variable "region" {
  description = "AWS region e.g. us-east-1"
  type        = string
  default     = "us-east-2"
}

variable "cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "AWS availability zones from region"
  default     = ["us-east-2a", "us-east-2b", "us-east-2c", ]
}

variable "private_subnets" {
  description = "CIDR for private subnets in the VPC (must be within var.cidr)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}


variable "private_subnets_workers" {
  description = "CIDR for public subnets in the VPC for kubernetes workers (must be within var.cidr)"
  type        = set(string)

  default = [
    "10.0.16.0/20",
    "10.0.32.0/20",
    "10.0.48.0/20",
  ]
}

variable "public_subnets" {
  description = "CIDR for public subnets in the VPC (must be within var.cidr)"
  type        = list(string)

  default = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
  ]
}

variable "public_subnets_workers" {
  description = "CIDR for public subnets in the VPC for kubernetes workers (must be within var.cidr)"
  type        = set(string)

  default = [
    "10.0.64.0/20",
    "10.0.80.0/20",
    "10.0.96.0/20",
  ]
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

variable "efs_volumes" {
  description = "efs volumes for the cluster"
  default = [
    "chain_archives",
    "dealbot",
  ]
}
