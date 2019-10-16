resource "aws_instance" "nginx" {
  instance_type = "t2.small"
  ami           = "ami-0607bfda7f358db2f"
  subnet_id     = "${aws_subnet.public.id}"
  key_name      = "${var.key_pair}"
  associate_public_ip_address = "true"
  vpc_security_group_ids = ["${aws_security_group.nginx.id}"]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    timeout     = "2m"
    agent       = false
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "file" {
    content     = "${data.template_file.nginx_faucet.rendered}"
    destination = "/tmp/nginx_faucet.conf"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get install software-properties-common",
      "sudo add-apt-repository -y universe",
      "sudo add-apt-repository -y ppa:certbot/certbot",
      "sudo apt-get -y update",
      "sudo apt-get -y install certbot nginx python-certbot-nginx",
      "sudo rm /etc/nginx/sites-enabled/default",
      "sudo cp /tmp/nginx_faucet.conf /etc/nginx/sites-available/nginx_faucet",
      "sudo ln -s /etc/nginx/sites-available/nginx_faucet /etc/nginx/sites-enabled/nginx_faucet",
      "sudo service nginx start",
    ]
  }
}

resource "null_resource" "configure-certbot" {
  depends_on = ["aws_route53_record.faucet"]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = "${aws_instance.nginx.public_ip}"
    timeout     = "2m"
    agent       = false
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo certbot --nginx -d ${aws_route53_record.faucet.fqdn} --non-interactive --agree-tos -m infra-accounts@protocol.ai",
    ]
  }
}
