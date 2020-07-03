# Filecoin network configuration

# The name of the network, i.e. "testnet"
variable "name" {}

# common aws variables.
variable "ami" {}
variable "key_name" {}
variable "azs" {
  type = list(string)
}
variable "domain_name" {}
variable "vpc_id" {}
variable "environment" {}

variable "public_subnets" {
  type = list(string)
}
variable "private0_cidr" {}
variable "private1_cidr" {}


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



variable "miner_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "miner_count" {
  type    = number
  default = 1
}
variable "miner_volumes" {
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
variable "scratch_volumes" {
  type    = number
  default = 0
}
