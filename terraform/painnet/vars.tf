variable "project_id" {
  description = "packet project id"
  default     = ""
}

variable "chainwatch_password" {}

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

variable "testnet_domain" {
  description = "the testnet domain managed in dnsimple"
  default     = "testnet.filecoin.io"
}
