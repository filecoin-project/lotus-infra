variable "boxes" {
  type = list
}

variable "boxes_default" {
  type = map
  default = {
    #ec2_type = "r5.2xlarge"
    github_username = ""
    ec2_type    = "t3.micro"
    volume_size = 2000
  }
}

variable "key_name" {
  type = string
  default = "filecoin"
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}
