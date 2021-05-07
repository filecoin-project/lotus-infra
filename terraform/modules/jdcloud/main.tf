provider "jdcloud" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}


resource "jdcloud_key_pairs" "ssh_key" {
  key_name   = "${var.name}-key"
  public_key = var.ssh_key
}

resource "jdcloud_vpc" "vpc" {
  vpc_name   = "${var.name}-${var.env}"
  cidr_block = "10.0.0.0/16"
}


resource "jdcloud_subnet" "public_a" {
  subnet_name = "${var.name}-${var.env}-subnet"
  vpc_id      = jdcloud_vpc.vpc.id
  cidr_block  = "10.0.0.0/24"
}

resource "jdcloud_route_table" "internet" {
  vpc_id           = jdcloud_vpc.vpc.id
  route_table_name = "${var.name}-${var.env}-rt"
}

resource "jdcloud_route_table_rules" "internet_rule" {
  route_table_id = jdcloud_route_table.internet.id
  rule_specs {
    next_hop_type  = "internet"
    next_hop_id    = "internet"
    address_prefix = "0.0.0.0/0"
  }
}

resource "jdcloud_route_table_association" "internet_to_subnet" {
  subnet_id      = [jdcloud_subnet.public_a.id]
  route_table_id = jdcloud_route_table.internet.id
}
