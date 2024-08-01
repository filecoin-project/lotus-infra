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
- 2x3.5TiB NVMe (RAID0 on /mnt/nvmeraid0)
- 4x16TiB HDDs (Currently not mounted, but can be found when running `lsblk` in the termina)
- RTX 2080 Ti

It is physical hardware located in the [Basefarm OSL5](https://www.datacentermap.com/norway/oslo/basefarm-osl5/) datacenter that @rjan90 setup.
