Just a little terraform to help make lotus images for people.


This terraform will setup a fullnode image using the "one-click" lotus images built
[here](https://github.com/filecoin-project/lotus/tree/master/tools/packer).

The one-click images are built by the lotus CI on every tag. This terraform adds an EBS volume that makes it easier to upgrade instances without destroying data.

## Terraform version: 12:28

## Adding a user

To add a user, add a name to the "oneclickusers" map at the top of the file, and then `terraform apply`

## Upgrading Lotus
1. Delete the instance (but not the EBS volume)
2. `terraform apply`

## Bugs / possible improvements for the future.

There is no way to manage multiple lotus versions. `terraform apply` would upgrade everything to the latest image.
