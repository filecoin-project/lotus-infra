variable "packet_auth_token" {
  type = string
}

variable "project_id" {
  type = string
}

variable "zone_id_name" {
  description = "testnet.fildev.network"
}

variable "zone_id" {
  description = "testnet.fildev.network"
}

variable "dnsimple_token" {
  description = "the secret dnsimple token"
}

variable "dnsimple_account" {
  description = "the secret dnsimple token"
}

variable "testnet_domain" {
  description = "the testnet domain managed in dnsimple"
  default     = "testnet.filecoin.io"
}

