variable "zone_id" {
  description = "fil-test.net"
}

variable "region" {
  default = "us-east-1"
}

variable "lotus_seed_copy_binary" {
  default = false
}

variable "lotus_seed_reset_repo" {
  default = "no"
}

variable "lotus_seed_binary_src" {
  default = "/tmp/lotus-seed"
}

variable "lotus_seed_sector_offset_0" {
  default = ["0", "2048", "4096", "6144", "8192"]
}

variable "lotus_seed_sector_offset_1" {
  default = ["1024", "3072", "5120", "7168", "9216"]
}

variable "lotus_seed_num_sectors" {
  description = "size of sectors to preseal"
  default     = "128"
}

variable "lotus_seed_sector_size" {
  description = "size of sectors to preseal"
  default     = "1073741824"
}

variable "cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "CIDR for private subnets in the VPC (must be within var.cidr)"
  type        = list
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "public_subnets" {
  description = "CIDR for public subnets in the VPC (must be within var.cidr)"
  type        = list

  default = [
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24",
  ]
}

variable "vault_password_file" {
  default = ""
}
