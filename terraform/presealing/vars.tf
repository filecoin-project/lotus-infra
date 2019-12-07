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
  default = "yes"
}

variable "lotus_seed_binary_src" {
  default = "/tmp/lotus-seed"
}

variable "lotus_seed_sector_offset" {
  default = ["0", "192", "384", "576", "768"]
}

variable "lotus_seed_num_sectors" {
  description = "size of sectors to preseal"
  default = "192"
}


variable "lotus_seed_sector_size" {
  description = "size of sectors to preseal"
  default = "1024"
}
