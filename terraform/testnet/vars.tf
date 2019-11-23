variable "project_id" {
  description = "packet project id"
  default     = ""
}

variable "packet_auth_token" {
  description = "packet api token"
}

variable "zone_id" {
  description = "fil-test.net"
}

variable "lotus_zone_id" {
  description = "lotu.sh"
}

variable "lotus_copy_binary" {
  default = false
}

variable "lotus_miner_copy_binary" {
  default = false
}

variable "lotus_fountain_copy_binary" {
  default = false
}
