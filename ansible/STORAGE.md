# Storage

To configure the external storage for a server you must first enable it through the terraform configuration.
You must also login to the server to find the correct device, as it may be different depending on the ec2 instance type.

You can then run the following to configure the device, you must provide the location where it should be mounted, and
the device itself that will be configured. You **MUST** limit the playbook to the correct host.

```
ansible-playbook -i $hostfile aws_attach_storage.yml --diff --limit scratch1 -e path=/storage -e device=/dev/nvme1n1
```

To transfer a lotus repo to the new storage location, turn off the lotus-daemon and all other services that depend on it.
In a tmux window run 

```
sudo rsync -av --progress /var/lib/lotus /storage
```

You must then update the `lotus_path` and apply the change before turning on the lotus daemon service.

## Resizing storage

First resize the ebs volume, this only covers how to **increase** the partition size.

Stop the lotus daemon and umount the volume
```
sudo systemctl stop lotus-daemon
sudo umount /storage
```

The GPT doesn't recognize the new space, I don't know how to fix this with fdisk,
but parted will do it automatically if you list the block device
```
sudo parted -l /dev/nvme1n1
Fix
```

> Warning: Not all of the space available to /dev/nvme1n1 appears to be used, you  
> can fix the GPT to use all of the space (an extra 671088640 blocks) or continue  
> with the current setting?  
> Fix/Ignore? **Fix**  

Resize the parition, the `First sector` **MUST** match the previous parition for things to align correct so no data is lost
```
sudo e2fsck -f /dev/nvme1n1p1
sudo fdisk /dev/nvme1n1
pdn<return><return><return>Nw
```

> $ sudo fdisk /dev/nvme1n1  
>   
> Welcome to fdisk (util-linux 2.31.1).  
> Changes will remain in memory only, until you decide to write them.  
> Be careful before using the write command.  
>   
>   
> Command (m for help): **p**  
> Disk /dev/nvme1n1: 512 GiB, 549755813888 bytes, 1073741824 sectors  
> Units: sectors of 1 * 512 = 512 bytes  
> Sector size (logical/physical): 512 bytes / 512 bytes  
> I/O size (minimum/optimal): 512 bytes / 512 bytes  
> Disklabel type: gpt  
> Disk identifier: 25C49948-8810-3843-9078-3282F2FAECCC  
>   
> Device         Start       End   Sectors  Size Type  
> /dev/nvme1n1p1  2048 402653150 402651103  192G Linux filesystem  
>   
> Command (m for help): **d**  
> Selected partition 1  
> Partition 1 has been deleted.  
>   
> Command (m for help): **n**  
> Partition number (1-128, default 1):  
> First sector (2048-1073741790, default 2048):  
> Last sector, +sectors or +size{K,M,G,T,P} (2048-1073741790, default 1073741790):  
> 
> Created a new partition 1 of type 'Linux filesystem' and of size 512 GiB.  
> Partition #1 contains a ext4 signature.  
>   
> Do you want to remove the signature? [Y]es/[N]o: **N**  
>   
> Command (m for help): **w**  
>   
> The partition table has been altered.  
> Calling ioctl() to re-read partition table.  
> Syncing disks.  

Resize the partition
```
sudo e2fsck -f /dev/nvme1n1p1
sudo resize2fs -p /dev/nvme1n1p1
```

Mount the partition again and start lotus
```
sudo mount /dev/nvme1n1p1 /storage
sudo systemctl start lotus-daemon
```
