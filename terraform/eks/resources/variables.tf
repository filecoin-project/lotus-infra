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

variable "private_subnets" {
  description = "CIDR for private subnets in the VPC (must be within var.cidr)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
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

variable "eks_iam_usernames" {
  description = "List of IAM usernames to grant EKS access"
  type        = list(string)

  default = [
    "marcus",
    "travisperson",
    "cory",
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

