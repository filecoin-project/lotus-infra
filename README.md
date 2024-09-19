# Lotus Infrastructure

A repository holding Lotus-related infrastructure

## Background

This repo has a long history from its days as a private repo within Protocol Labs Inc during the initial ~4 years of Lotus' development and maintenance.  In 202402, this repo came under the ownership/stewardship of [FilOz](http://filoz.org/).  Since then, this repo has been primarily stripped down to supporting the Butterfly developer network, which is used by Lotus maintainers and other close contributors.  In an effort to work more in public and give more insight into Lotus' development process, this repo was made public.  At least as of 202409, it hasn't been fully cleaned up (i.e., there is kruft), but it's better than it being locked behind GitHub's private access flag.  While this repo is here primarily to support the Lotus and related software's maintenance and development efforts that FilOz engages in, ideas and contributions are welcome.

## Terraform

The keypair used to spin up EC2 instances is set to `lotus-infra-ec2`. This key is added to 1Password at `Infra` vault, `lotus-infra-ec2 SSH Key` secret.

The SSH private key is also present as CI secrets under `EC2_SSH_KEY`.

### Butterfly Networks  

Located in `terraform/testnets` this manages AWS assets for Butterfly Network core infrastructure.
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
- 4x16TiB HDDs (Currently not mounted, but can be found when running `lsblk` in the terminal)
- RTX 2080 Ti

It is physical hardware located in the [Basefarm OSL5](https://www.datacentermap.com/norway/oslo/basefarm-osl5/) datacenter that @rjan90 setup.
