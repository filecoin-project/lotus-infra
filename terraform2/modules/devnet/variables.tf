# Filecoin network configuration

# The name of the network, i.e. "testnet"
variable "name" {}

# common aws variables.
variable "ami" {}
variable "key_name" {}
variable "zone_id" {}
variable "vpc_id" {}
variable "environment" {}

variable "private_subnet_id" {}
variable "public_subnet_id" {}
variable "private_subnet_cidr" {}
variable "public_subnet_cidr" {}
variable "database_subnet_group" {}

variable "preminer_iam_profile" {}

# Variables for tools
variable "toolshed_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "chainwatch_db_instance_type" {
  type    = string
  default = "db.t2.micro"
}
variable "chainwatch_username" {
  type    = string
  default = "chainwatch"
}
variable "chainwatch_password" {
  type    = string
  default = "insecure"
}
variable "chainwatch_port" {
  type    = number
  default = 5432
}



variable "preminer_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "preminer_count" {
  type    = number
  default = 1
}

variable "bootstrapper_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "bootstrapper_count" {
  type    = number
  default = 1
}


variable "scratch_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "scratch_count" {
  type    = number
  default = 0
}

variable "timescale_ami" {
  type = string
}
variable "timescale_instance_type" {
  type    = string
  default = "t2.micro"
}
