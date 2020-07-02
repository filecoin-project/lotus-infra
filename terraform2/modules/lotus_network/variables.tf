# Filecoin network configuration

# The name of the network, i.e. "testnet"
variable "name" {}

# common aws variables.
variable "ami" {}
variable "key_name" {}
variable "availability_zone" {}
variable "domain_name" {}
variable "environment" {}

# chainwatch variables

variable "chainwatch_instance_type" {
  type = string
  default = "t2.micro"
}

variable "chainwatch_password" {
  type = string
  default = "insecure"
}

variable "chainwatch_port" {
  type = number
  default = 5432
}

# faucet variables

variable "faucet_instance_type" {
  type = string
  default = "t2.micro"
}

# stats variables

variable "stats_instance_type" {
  type = string
  default = "t2.micro"
}

# Miner variables

variable "miner_instance_type" {
  type = string
  default = "t2.micro"
}

variable "miner_count" {
  type = number
  default = 1
}

variable "miner_volumes" {
  type = number
  default = 1
}

# Bootstrapper variables

variable "bootstrapper_instance_type" {
  type = string
  default = "t2.micro"
}

variable "bootstrapper_count" {
  type = number
  default = 1
}
