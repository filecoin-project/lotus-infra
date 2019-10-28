# Lotus Ansible Playbook

This playbook is designed to be as modular and extendable as possible.

Playbooks are organized in to individual files with `lotus.yml` being a single playbook that includes all other playbooks.

Roles are used to modularize components and allow re-usability.

## Secrets

Secrets are managed by [ansible-vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html). Global secrets such as passwords for influxdb and logz.io are kept in `group_vars/all/vault.yml`.

To run playbooks, it's suggested you create a vault password file for convenience.

### Instructions

1. In 1password `filecoin dev` vault, get the `lotus ansible vault` password
2. Storge the password in a file called `$HOME/.ansible_vault_pass.txt`

## Current playbooks

### Filebeat

Can be used to install and configure Filebeat on any Ubuntu host. Creates a valid configuration to send logs to logz.io

#### Instructions

1. Optionally add your host to `devnet_hosts` in global section. See [working with inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) for more details.
2. Run `ansible-playbook` in check mode. This performs a dry run.
        ansible-playbook -i devnet_hosts filebeat.yml --vault-password-file $HOME/.ansible_vault_pass.txt --check
   To target a single host, include the limit flag ie. `--limit some.host.com`
3. If step 2 is satisfactory, run the same command without `--check` flag
4. SSH in to host(s) and run `systemctl status filebeat` to verify service is installed and running

### Telegraf

Can be used to install and configure Telegraf on any Ubuntu host. Creates a valid configuration to send metrics to influxdb cloud.

#### Instructions

1. Optionally add your host to `devnet_hosts` in global section. See [working with inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) for more details.
2. Run `ansible-playbook` in check mode. This performs a dry run.
        ansible-playbook -i devnet_hosts telegraf.yml --vault-password-file $HOME/.ansible_vault_pass.txt --check
   To target a single host, include the limit flag ie. `--limit some.host.com`
3. If step 2 is satisfactory, run the same command without `--check` flag
4. SSH in to host(s) and run `systemctl status telegraf` to verify service is installed and running

### Lotus

This playbook is the intended playbook for setting up machines running lotus nodes. This could be changed as roles and playbooks evolve.

1. Optionally add your host to `devnet_hosts` in global section. Hosts should also be added to the `[lotus]` section of inventory. See [working with inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) for more details.
2. Run `ansible-playbook` in check mode. This performs a dry run.
        ansible-playbook -i devnet_hosts ltous.yml --vault-password-file $HOME/.ansible_vault_pass.txt --check
   To target a single host, include the limit flag ie. `--limit some.host.com`
3. If step 2 is satisfactory, run the same command without `--check` flag
