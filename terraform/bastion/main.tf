resource "null_resource" "ssh_key" {
  provisioner "local-exec" {
    command = "ssh-keygen -N ${var.ssh_key_password} -f /tmp/bastion-key"
  }
}

resource "null_resource" "ssh_cleanup_key" {
  depends_on = ["packet_device.bastion"]

  provisioner "local-exec" {
    command = "rm -f /tmp/bastion-key || true"
  }
}

resource "packet_device" "bastion" {
  hostname            = "lotus-bastion"
  plan                = "x1.small.x86"
  facilities          = ["yyz1"]
  operating_system    = "ubuntu_19_04"
  billing_cycle       = "hourly"
  project_id          = "${var.project_id}"
  user_data           = "${templatefile("${path.module}/templates/user_data.sh.tpl", { terraform_version = "${var.terraform_version}" })}"
  project_ssh_key_ids = "${values(local.ssh_keys)}"

  connection {
    type  = "ssh"
    user  = "root"
    host  = "${self.access_public_ipv4}"
    agent = true
  }

  provisioner "file" {
    source      = "/tmp/bastion-key"
    destination = "/root/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /root/.ssh/id_rsa",
    ]
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = "${var.route53_zone_id}"
  name    = "bastion"
  type    = "A"
  ttl     = "300"
  records = ["${packet_device.bastion.access_public_ipv4}"]
}

locals {
  ssh_keys = {
    whyrusleeping  = "c322d08b-6a7b-4a81-99b1-8eec718a8377"
    whyrusleeping2 = "f9fb98a4-7763-42ff-99f2-101f6a616eac"
    whyrusleeping3 = "3890262b-00e2-4b7f-98c5-f748d7e15f46"
    kubuxu         = "2c7b5374-2cd9-4206-9f9d-ca0d443e77f4"
    magik6k        = "d8f6e481-3204-4bd7-8922-81a33a46d28e"
    magik6k2       = "cbf19736-a4ca-4cd1-8982-6404869edb91"
    magik6k3       = "b6d323cd-773b-4e63-8098-405e9ba5cf9e"
    ognots         = "e0eb55a6-b2e7-48f8-9bd9-a7c5987332dc"
    travisperson   = "e9febf12-1da7-43b3-b326-3f84a3ad47fa"
  }
}
