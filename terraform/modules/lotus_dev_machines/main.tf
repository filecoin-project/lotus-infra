locals {
  machines_default = {
    github_username = ""
    ec2_type        = "r5.2xlarge"
    volume_size     = 2000
    region          = "us-east-2"
    ami             = ""
  }
  machines = tomap({
    for b in var.machines : b.github_username => merge(local.machines_default, b)
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "mod" {
  for_each      = local.machines
  ami           = each.value.ami != "" ? each.value.ami : data.aws_ami.ubuntu.id
  instance_type = each.value.ec2_type
  key_name      = var.key_name
  root_block_device {
    delete_on_termination = false
    tags = {
      github_username = each.value.github_username
      role            = "development"
    }
    volume_size = each.value.volume_size
    volume_type = "gp2"
  }
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  tags = {
    github_username = each.value.github_username
    role            = "development"
  }

  user_data = templatefile("${path.module}/templates/fetch_ssh_key.bash.tpl", {
    github_username = each.value.github_username
    ubuntu_user     = "ubuntu"
    home_dir        = "/home/ubuntu"
  })
}
