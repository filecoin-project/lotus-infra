data "aws_ami" "mainnet" {
  most_recent = true
  filter {
    name = "name"
    values = [ "lotus-mainnet-v1.5.3-*" ]
  }
  owners = [ 657871693752 ]
}

resource "aws_instance" "mainet-willscot" {
  ami = data.aws_ami.mainnet.id
  instance_type = "t3.2xlarge"
  tags = {
    name = "lotus-willscot"
    lotus-version = "1.5.3"
    lotus-network = "mainnet"
    owner = "Will Scot"
  }
}
