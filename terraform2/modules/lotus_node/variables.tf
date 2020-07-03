variable "instance_type" {
  type = string
}

variable "ami" {
  type = string
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

variable "lotus_network" {
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

variable "volumes" {
  type    = number
  default = 0
}
