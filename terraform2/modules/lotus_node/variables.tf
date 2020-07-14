variable "instance_type" {
  type = string
}

variable "ami" {
  type = string
}

variable "iam_instance_profile" {
  type    = string
  default = ""
}

variable "key_name" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "name" {
  type = string
}

variable "network_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "scale" {
  type    = number
  default = 1
}

variable "private_security_group_ids" {
  type = list(string)
}

variable "public_security_group_ids" {
  type = list(string)
}

variable "private_subnet_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}
