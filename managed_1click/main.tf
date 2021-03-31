provider "aws" {
  region = "us-east-1"
  profile = "filecoin"
}

terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "1click-terraform.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
    profile        = "filecoin"
  }
}

data "aws_ami" "mainnet" {
  most_recent = true
  filter {
    name = "name"
    values = [ "lotus-mainnet-v1.5.3-*" ]
  }
  owners = [ 657871693752 ]
}

// Map between user and their SSH key.
// https://github.com/willscott.keys
// https://github.com/acruikshank.keys
variable "oneclickusers" {
  description = "one-click instances we manage for people"
  default = {
    "willscot" =  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/RMGjrpi7C7g8cwCuYjgjAskc8Cask4BMSwxXwQ+2O6B704dvjrew/WXKSOE53bOVjbr3pLMd5EuWOaYPZlSYgIz0EdOZXzxjB5QJAMmk8pZDERaeAWTUhOiGLA1iG4hBX+LEON0US8LZWNWaj87KbZF+LcdsrBSMbdB83LvYMvgg0VHYuMb5gEUrFz6aABkaKqgYYd578o5/ObT1UqM9QvdpimH/pFhaT8ZhSq/c9b/7exA1GUyRbHeEdNO4GJPCjcVmVD5PVH5Iw1ZYEeEcX49a8hxT7209pwfn5Dv82Mcw8fxHDz/ZBfaqYdY9KhASs2BQ1vq+UkRvZXuy8BI1wgctfF06okYQeFToCMHgCjBJMxlr0SU13XvDsCJSmM9c7nyP4CKqtD0i5V8FsA6V7gK6SYW2KE1iAvXYq6pbY/1IRftErNcBj5SF5ZTS8ePjJ4xIjQGZT8fIyG6eE3baionf8nr5G3aOUvF/ztdfqSEjGMwdhzcba83kFW5hpnwCS09W+NfqSpEenMqyTwLxgFMYLfXC+mx5CCwQAb9sThdQ7SE/sEPkCFJ7Q9618VhnoWtLu1zUMjK4yU6fsym5EC6eb7G8sn68FjhuXNTx72OTvyPcTiTd7Dp5Eg7NdBcn1PNaW8nGX8/JXcAFNVGqJGbTmzXgFP3z7+BSlbSdfw=="
    "alexcruikshank" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDwXg25uubw6iOi49+lsF4SCuOlQueRVsMs+cDbmIDO0TTzrw4Y4znvjm93+6WXmEQyG9JlJdhRjqveGCcD1HbcwX4xjQR8WhPcSH2sOY9Axj9BDwgdBcIYixuvTUADo7QrYlkbfZAlkLeNpR8z9DaYlmG76OrMT38B7LEF9JuyYNu4t4bs4aTx8CSfCmJSBpWGz/jkvaylW35lA/UqE286ILVU5B2MmjgwG5ZRYpJ+2E+knauX+5mOWnoy0AHqAoI4uI8eqOZHwsmKF3ilqvsDKNBmqFgtYTodxxZDQOdQ3JgYWmKOl/0xfkobNRszz6lntzTFWiM9M7YKBweeOYNR"
  }
}

resource "aws_key_pair" "oneclickkeys" {
  for_each = var.oneclickusers
  key_name = each.key
  public_key = each.value
}


resource "aws_instance" "oneclickinstance" {
  for_each = var.oneclickusers
  ami = data.aws_ami.mainnet.id
  instance_type = "r5.2xlarge"
  key_name = aws_key_pair.oneclickkeys[each.key].key_name
  tags = {
    Name = format("%s-%s", "mainnet", each.key)
    Lotus-version = "1.5.3"
    Lotus-network = "mainnet"
    Owner = each.key
  }
  user_data = file("user_data.sh")
}
