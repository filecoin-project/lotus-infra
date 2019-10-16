variable "key_pair" {
  # 93:14:5b:b2:d5:e6:f6:79:89:9c:06:45:49:16:65:f4
  default = "filecoin"
}

variable "private_key_file" {
  # 93:14:5b:b2:d5:e6:f6:79:89:9c:06:45:49:16:65:f4
  description = "Private key of the 'filecoin' key pair of us-east-1"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "filecoin"
}

variable "zone_id" {
  # This zone is not managed by any terraform in this project atm
  # kittyhawk.wtf.
  default = "Z4QUK41V3HPV5"
}
