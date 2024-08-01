# Lotus Infrastructure

A repository holding Lotus related infrastructure

## Terraform

### Calibration and Butterfly Networks  

Located in `terraform/testnets` this manages AWS assets for Calibration and Butterfly Network core infrastructure.
It's recommended to install [asdf](https://github.com/asdf-vm/asdf) and the [terraform plugin](https://github.com/asdf-community/asdf-hashicorp) locally, for proper terraform version management.

## Ansible

A collection of roles and playbooks to use for Lotus infrastructure.

Aims to be non-opinionated and modular, allowing targeted provisioning and playbook runs

See `ansible/README.md` for more information

## ArchiOz
### Physical Infrastructure
At least as of 2024-08-01, ArchiOz is single machine with these specs:
- AMD EPYC 7F32 8-Core Processor
- 512GiB of RAM
- 7TiB of NVMe
- 60TiB of HDD iirc (Currently not mounted)
- RTX 2080 Ti

It is physical hardware located in X that @rjan90 setup.
