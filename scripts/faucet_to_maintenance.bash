#!/usr/bin/env bash

# This script will set the faucet into a maintenance mode.
# A simple website will be displayed instead of the faucet landing page.

set -xe

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd $SCRIPTDIR/../ansible

ansible-playbook --vault-password-file .vault_password          \
  -i testnet_hosts.yml lotus_fountain.yml                       \
  -e lotus_daemon_bootstrap="true"                              \
  -e lotus_fountain_server_name="faucet.testnet.filecoin.io"    \
  -e certbot_create_certificate=false                           \
  -e lotus_fountain_enabled=false

popd
