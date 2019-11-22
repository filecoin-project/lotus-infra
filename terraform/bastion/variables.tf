variable "project_id" {
  description = "packet project id"
  default     = ""
}

variable "terraform_version" {
  description = "version of terraform to install"
  default     = "0.12.16"
}

variable "ssh_key_password" {
  type        = "string"
  description = "password for encrypted SSH key"
}

variable "packet_auth_token" {
  description = "packet api token"
}

variable "route53_zone_id" {
  description = "route53 zone id to use for bastion A record"
  default     = "Z3LWP4KWBL3A59"
}
