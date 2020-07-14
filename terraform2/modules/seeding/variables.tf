# Filecoin sealing configuration

variable "name" {}

# common aws variables.
variable "ami" {}
variable "key_name" {}
variable "zone_id" {}
variable "vpc_id" {}
variable "environment" {}

variable "public_subnet_id" {}
variable "public_subnet_cidr" {}

variable "presealer_iam_profile" {}

variable "presealer_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "presealer_count" {
  type    = number
  default = 1
}

variable "volume_size" {
  type    = number
  default = 128
}
