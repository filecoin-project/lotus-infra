prefix = "mainnet-us-east-2-dev"
region = "us-east-2"
external_dns_zone_id = "Z101364637Q9PPC6K9NRV"
external_dns_fqdn = "fildevops.net"
key_name = "filecoin"
azs = ["us-east-2a", "us-east-2b", "us-east-2c"]

kubeconfig_aws_authenticator_env_variables = {
  AWS_PROFILE = "filecoin"
}
aws_profile = "filecoin"
