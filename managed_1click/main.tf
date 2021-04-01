// Map between user and their SSH key.
// https://github.com/willscott.keys
// https://github.com/acruikshank.keys

variable "oneclickusers" {
  description = "one-click instances we manage for people"
  default = {
    "willscot" =  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/RMGjrpi7C7g8cwCuYjgjAskc8Cask4BMSwxXwQ+2O6B704dvjrew/WXKSOE53bOVjbr3pLMd5EuWOaYPZlSYgIz0EdOZXzxjB5QJAMmk8pZDERaeAWTUhOiGLA1iG4hBX+LEON0US8LZWNWaj87KbZF+LcdsrBSMbdB83LvYMvgg0VHYuMb5gEUrFz6aABkaKqgYYd578o5/ObT1UqM9QvdpimH/pFhaT8ZhSq/c9b/7exA1GUyRbHeEdNO4GJPCjcVmVD5PVH5Iw1ZYEeEcX49a8hxT7209pwfn5Dv82Mcw8fxHDz/ZBfaqYdY9KhASs2BQ1vq+UkRvZXuy8BI1wgctfF06okYQeFToCMHgCjBJMxlr0SU13XvDsCJSmM9c7nyP4CKqtD0i5V8FsA6V7gK6SYW2KE1iAvXYq6pbY/1IRftErNcBj5SF5ZTS8ePjJ4xIjQGZT8fIyG6eE3baionf8nr5G3aOUvF/ztdfqSEjGMwdhzcba83kFW5hpnwCS09W+NfqSpEenMqyTwLxgFMYLfXC+mx5CCwQAb9sThdQ7SE/sEPkCFJ7Q9618VhnoWtLu1zUMjK4yU6fsym5EC6eb7G8sn68FjhuXNTx72OTvyPcTiTd7Dp5Eg7NdBcn1PNaW8nGX8/JXcAFNVGqJGbTmzXgFP3z7+BSlbSdfw=="
    "alexcruikshank" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDwXg25uubw6iOi49+lsF4SCuOlQueRVsMs+cDbmIDO0TTzrw4Y4znvjm93+6WXmEQyG9JlJdhRjqveGCcD1HbcwX4xjQR8WhPcSH2sOY9Axj9BDwgdBcIYixuvTUADo7QrYlkbfZAlkLeNpR8z9DaYlmG76OrMT38B7LEF9JuyYNu4t4bs4aTx8CSfCmJSBpWGz/jkvaylW35lA/UqE286ILVU5B2MmjgwG5ZRYpJ+2E+knauX+5mOWnoy0AHqAoI4uI8eqOZHwsmKF3ilqvsDKNBmqFgtYTodxxZDQOdQ3JgYWmKOl/0xfkobNRszz6lntzTFWiM9M7YKBweeOYNR"
    "cory" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiwx4Vw4oVp/WaxHFqd85KdvQ03E78mUcjD7wr6XRl7xFssVg+NQAoBc1UVKpavrDFcbYHAcEWQbvY//izmloGql1CbhNBEp9pHNHe1QJLChPZDJ0J4ljCHCtWTYQqYXhF5j7qefQjZ/chwbJJIV/47koUKXjJUFW7ohtF07WGr8SGXn3oSrP+8lynj9I7JHRX5XbzcID7qlQ5pX52mCzNkrESrhUi+KIMo0d9i0EyhJKNT+qDVwLBoaqDb5vtLSixNE4LLlsC6xp/YnE3dEY2vLyapfiBddsDxfFQJaqjZ7qlQgsWOuwwDNJOrzOSmLTqZ5wgTG2ViVv32Ngen16bLTH4V2E3h5M6meHFpgZT0lhU8wGP/qmvFmwOvsTMmGu+kmtvs3Pov5B3li7AgOOneYs7/PP74WZL74kg63cZ7yUMAZo7FcTTWwyQhdphCmwDH7ymVIQEUPlfyh85jt2Q2mkBMQc+7f6NhxZVMGc7WYcIDRXmXwyJlDai7xNtTQs= cory@nemesis"
  }
}


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
    values = [ "lotus-mainnet-*" ]
  }
  owners = [ 657871693752 ]
}

data "aws_ami" "calibrationnet" {
  most_recent = true
  filter {
    name = "name"
    values = [ "lotus-calibrationnet-*" ]
  }
  owners = [ 657871693752 ]
}

data "aws_ami" "nerpanet" {
  most_recent = true
  filter {
    name = "name"
    values = [ "lotus-nerpanet-*" ]
  }
  owners = [ 657871693752 ]
}


// it is okay to open up all traffic because these boxes are running a host
// firewall. This might seem odd on AWS, but this is a requirement for
// digitalocean 1-click apps, so the same behavior is replicated here.
resource "aws_security_group" "alltraffic" {
  name = "oneclick allow all"
  ingress {
    description = "permissive inbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "permissive outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair" "oneclickkeys" {
  for_each = var.oneclickusers
  key_name = format("oneclick-%s", each.key)
  public_key = each.value
}


// Mainnet
resource "aws_instance" "oneclickmainnetinstance" {
  for_each = var.oneclickusers
  ami = data.aws_ami.mainnet.id
  instance_type = "r5.2xlarge"
  key_name = aws_key_pair.oneclickkeys[each.key].key_name
  tags = {
    Name = format("oneclick-mainnet-%s", each.key)
    Lotus-network = "mainnet"
    Owner = each.key
  }
  security_groups = [ aws_security_group.alltraffic.name ]
  user_data = file("user_data.sh")
  availability_zone = "us-east-1f"
}

resource "aws_ebs_volume" "oneclickmainnetvolume" {
  for_each = var.oneclickusers
  /* availability_zone = aws_instance.oneclickmainnetinstance[each.key].availability_zone */
  availability_zone = "us-east-1f"
  size = 1000
  type = "gp2"
}

resource "aws_volume_attachment" "oneclickmainnetattachment" {
  for_each = var.oneclickusers
  device_name = "/dev/sdf"
  volume_id = aws_ebs_volume.oneclickmainnetvolume[each.key].id
  instance_id = aws_instance.oneclickmainnetinstance[each.key].id
}

// Calibrationnet
resource "aws_instance" "oneclickcalibrationnetinstance" {
  for_each = var.oneclickusers
  ami = data.aws_ami.calibrationnet.id
  instance_type = "r5.2xlarge"
  key_name = aws_key_pair.oneclickkeys[each.key].key_name
  tags = {
    Name = format("oneclick-calibrationnet-%s", each.key)
    Lotus-network = "calibrationnet"
    Owner = each.key
  }
  security_groups = [ aws_security_group.alltraffic.name ]
  user_data = file("user_data.sh")
  availability_zone = "us-east-1f"
}

resource "aws_ebs_volume" "oneclickcalibrationnetvolume" {
  for_each = var.oneclickusers
  /* availability_zone = aws_instance.oneclickcalibrationnetinstance[each.key].availability_zone */
  availability_zone = "us-east-1f"
  size = 1000
  type = "gp2"
}

resource "aws_volume_attachment" "oneclickcalibrationnetattachment" {
  for_each = var.oneclickusers
  device_name = "/dev/sdf"
  volume_id = aws_ebs_volume.oneclickcalibrationnetvolume[each.key].id
  instance_id = aws_instance.oneclickcalibrationnetinstance[each.key].id
}

// Nerpanet
resource "aws_instance" "oneclicknerpanetinstance" {
  for_each = var.oneclickusers
  ami = data.aws_ami.nerpanet.id
  instance_type = "r5.2xlarge"
  key_name = aws_key_pair.oneclickkeys[each.key].key_name
  tags = {
    Name = format("oneclick-nerpanet-%s", each.key)
    Lotus-network = "nerpanet"
    Owner = each.key
  }
  security_groups = [ aws_security_group.alltraffic.name ]
  user_data = file("user_data.sh")
  availability_zone = "us-east-1f"
}

resource "aws_ebs_volume" "oneclicknerpanetvolume" {
  for_each = var.oneclickusers
  /* availability_zone = aws_instance.oneclicknerpanetinstance[each.key].availability_zone */
  availability_zone = "us-east-1f"
  size = 1000
  type = "gp2"
}

resource "aws_volume_attachment" "oneclicknerpanetattachment" {
  for_each = var.oneclickusers
  device_name = "/dev/sdf"
  volume_id = aws_ebs_volume.oneclicknerpanetvolume[each.key].id
  instance_id = aws_instance.oneclicknerpanetinstance[each.key].id
}
