#!/bin/bash
set -e

apt-get update
apt-get upgrade -y
apt install software-properties-common
apt-add-repository ppa:ansible/ansible
apt-get update
apt-get install -y ansible curl unzip git
pushd /tmp
wget https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip
unzip terraform_${terraform_version}_linux_amd64.zip
mv terraform /usr/local/bin/terraform
shutdown -r now
