variable "name" {
  type        = string
  description = "The name of the server. Should be unique in the form [a-z0-9-]."
}

variable "env" {
  type        = string
  description = "An environment string (used for tagging resources)."
  default     = "mainnet"
}

variable "ssh_key" {
  type        = string
  description = "An SSH key to be attached to instances launched for worst-case debugging."
}

variable "az" {
  type        = string
  description = "Availability zone for the instance"
}

variable "image_id" {
  type        = string
  description = "The JDCloud image id to use"
}

variable "region" {
  type    = string
  default = "cn-south-1"
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}
