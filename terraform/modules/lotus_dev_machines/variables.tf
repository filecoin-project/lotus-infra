variable "machines" {
  type = list
}

variable "key_name" {
  type    = string
  default = "filecoin"
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "ami" {
  type    = string
  default = "ami-03f4121463e28151e"
}
