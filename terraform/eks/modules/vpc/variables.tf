variable "prefix" {
  description = "Prefix name to tag resources with"
  type        = string
}

variable "region" {
  description = "AWS region e.g. us-east-1"
  type        = string
  default     = "us-east-2"
}

variable "azs" {
  description = "AWS availability zones from region"
  default     = ["us-east-2a", "us-east-2b", "us-east-2c", ]
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

variable "aws_profile" {
  description = "AWS Profile to use when applicable"
}
