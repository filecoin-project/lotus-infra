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
