# Lotus Ansible Playbook

This playbook is designed to be as modular and extendable as possible.

Playbooks are organized in to individual files with `lotus.yml` being a single playbook that includes all other playbooks.

Roles are used to modularize components and allow re-usability.


## Secrets

Secrets are managed by [ansible-vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html). Global secrets such as passwords are kept in `group_vars/all/vault.yml`.

To run playbooks, it's suggested you create a vault password file for convenience.

### Instructions

1. In 1password `filecoin dev` vault, get the `lotus ansible vault` password
2. Store the password in a file called `./ansible/.vault_password`

## Current playbooks

### Lotus

This playbook is the intended playbook for setting up machines running lotus nodes. This could be changed as roles and playbooks evolve.

1. Optionally add your host to `devnet_hosts` in global section. Hosts should also be added to the `[lotus]` section of inventory. See [working with inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) for more details.
2. Run `ansible-playbook` in check mode. This performs a dry run.
        ansible-playbook -i devnet_hosts lotus.yml --vault-password-file $HOME/.ansible_vault_pass.txt --check
   To target a single host, include the limit flag ie. `--limit some.host.com`
3. If step 2 is satisfactory, run the same command without `--check` flag

The following SSH config makes it easier to SSH into butterflynet machines stood up by ansible. Add it to your `~/.ssh/config`, and once added you can simply run `ssh butterflynet-bootstrap-0` as an example. Note, for this to work you must have ssh access to the machines to begin with.

```
Host butterflynet-bootstrap-0
 HostName bootstrap-0.butterfly.fildev.network
 User ubuntu

Host butterflynet-bootstrap-1
 HostName bootstrap-1.butterfly.fildev.network
 User ubuntu

Host butterflynet-preminer-0
 HostName preminer-0.butterfly.fildev.network
 User ubuntu

Host butterflynet-preminer-1
 HostName preminer-1.butterfly.fildev.network
 User ubuntu

Host butterflynet-preminer-2
 HostName preminer-2.butterfly.fildev.network
 User ubuntu

Host butterflynet-scratch-0
 HostName scratch-0.butterfly.fildev.network
 User ubuntu

Host butterflynet-toolshed-1
 HostName toolshed-1.butterfly.fildev.network
 User ubuntu
```

## Vagrant

NOTE: this has not maintained, and is not recently tested.

Vagrant can be used to test role / playbook development agasint a locally running vm.

```
$ vagrant up --provision
$ ansible-playbook -i hosts-vagrant <playbook>.yml --vault-password-file $HOME/.ansible_vault_pass.txt
```

When provisioning vagrant will run the `vagrant.yml` playbook. This playbook should maintain a minimal amount of configuration.
