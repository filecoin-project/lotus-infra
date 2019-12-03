variable "project_id" {
  description = "packet project id"
  default     = ""
}

variable "packet_auth_token" {
  description = "packet api token"
}

variable "dnsimple_token" {
  description = "the secret dnsimple token"
}

variable "dnsimple_account" {
  description = "the secret dnsimple token"
  default     = "70480"
}

variable "zone_id" {
  description = "fil-test.net"
}

variable "lotus_zone_id" {
  description = "lotu.sh"
}

variable "testnet_domain" {
  description = "the testnet domain managed in dnsimple"
  default     = "testnet.filecoin.io"
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

variable "certbot_create_certificate" {
  default = false
}

variable "lotus_reset" {
  default = false
}

