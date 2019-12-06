variable "zone_id" {
  description = "fil-test.net"
}

variable "lotus_seed_sector_size" {
  description = "size of sectors to preseal"
  default = "1024"
}

variable "lotus_seed_num_sectors" {
  description = "size of sectors to preseal"
  default = "1"
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

