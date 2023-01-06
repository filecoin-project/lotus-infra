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

resource "aws_instance" "mod" {
  for_each      = local.machines
  ami           = each.value.ami != "" ? each.value.ami : var.ami
  instance_type = each.value.ec2_type
  key_name      = var.key_name

  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  volume_tags = {
    github_username = each.value.github_username
    role            = "development"
    isproduction    = "1"
    project         = "lotus"
    dri             = "${each.value.github_username}@protocol.ai"
  }

  root_block_device {
    delete_on_termination = false
    volume_size           = each.value.volume_size
    volume_type           = "gp2"
  }

  tags = {
    github_username = each.value.github_username
    role            = "development"
    isproduction    = "1"
    project         = "lotus"
    dri             = "${each.value.github_username}@protocol.ai"
  }

  user_data = templatefile("${path.module}/templates/fetch_ssh_key.bash.tpl", {
    github_username = each.value.github_username
    ubuntu_user     = "ubuntu"
    home_dir        = "/home/ubuntu"
  })

  lifecycle {
    ignore_changes = [
      root_block_device[0].volume_size
    ]
  }
}
