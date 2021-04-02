#!/usr/bin/env bash

echo FILECOIN USER DATA STARTED

# Terraform can't apply multiple SSH keys easily, so install it now.
# https://gist.github.com/mgoelzer/0b6c74fce8ca29ca3c2db022ed53098e

echo MODIFYING UBUNTU SSH KEY

dealbot="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQCuLeJop7phQkZzB6pJH7yn0uaPnXa+55Z4rvvBV8bSAwLh6d+sfapuCepw0szvU/yD+IJRTvDZx5lyjVte0mBmhMKtWHvZdoPMcraxQ0ZPg9FSTU66S3r2QHR5J98qN48kHea+Lf/q3bqeULM/j7QJL7AV12TLC/if2w7PZBB5QeKUN2eSuf7UjEAz4mgJ93UWtaYrPqhp4DJXYqaFyhD7Xslei/d0qOG+y4ju18gq9dTLcZRpewBy2kkwBt1OW9Yol9yiawU3kllzmeU/8P3rAvjcyRsWrRkG+VVE1v4tn6NG/a+RZqfLXmt+ES61j486Pp1La0GEjJ03tozOBT51jX9apQvC3jo0nWrr7HOxZ+YwhU1LslpfVarD5MDPkL/2v2FmWwblKt4mZKWCFU4qp6wgdpBKM+MxcYyNNXz+f9jrEee059NAsrJirJATYTgHPq/VT0hfejMbSmefEqjKW/k+U0LYKx9su2ygAsxa5ffwFHRil+LHCJ1JON4bWihDcjEVTvHXqkWGXOKnWhA9zv95wa1NULBuGbmcxnBktK34ME4hivLg+huvbTxzPWYBIZMeB4t/To0Dg2Ye9pCs8fgz3CsEjEyZcu0+cdk4qR/dcgPzHumsm3vWJB221ctk7Zq/BVoJlpPWSy8FFuNSkJLHi27veCQ8PSXbOHxnNjJJVWZtZd1BBc6eQtJIWOTuoUb59ArXbgUTE4Al498B0Fm39C8l3B9hCzDCNSOmiXPhNeGo31x2bOOb9NEn5GcLQlp/KXMPPdI9Ot1+wYGiDShNNhDGl83mtrZoLWWTG874hW2JjzPqVLJeM8e9Fu9A6ORAjOwOzZSUvGbF8uQMzumhjAMgHsxdbVZeNxngwoQa+qxgPlRv9ZTWm9PLxzcRKwARKindo5Cr91hyrArj05738yxBoTTQE0owO1HYhzIAzZgAt283YUKx/J6Tm09rrMpVlpyPqf8ybs4ldpd38DC0RF82ZQaG8RW1dFPYOAqrVaGvubshxRhsDWjjcVxTl+8TvtXINzbG1YjmKonUgRPxNpONcRyB2zCzGThxcE0LmjOXb7xs9s4IxU2jubC57YJCRYW5TxWxSecVN9+PE7QJEfDJ2Nkqs9mvfEjqsQF8dGIHq8OaO4SvRfkJEJgDZtuDmmdqXF/LQA+BDJM/hBeM9zaZAYK8pW6/6Ar66sG5OGvgrHmGIbcQfw0IAhgYtjbjnmKIjolJMGzNT8AyS4rZ7ZqM2FAKRFgA3hZ2EaES66IOVmwqhKz/bXDHwqVN5Lrphv2ZIF86fYps2pYmTVcxLvxcgAfICfH/hbX/Y9jyS8CNCVw6vpT3UeXCGUcc4gBseveF/WaCN8Pu8eRH mwg@libp2me"

echo "${dealbot}" >> /home/ubuntu/.ssh/authorized_keys

# The rest of this script has to do with making use of the EBS volume

echo STOPPING LOTUS
# Stop lotus for now.
systemctl stop lotus-daemon

# remove any files that might have been created already,
# and prevent them from accidently being created again.
rm -rf /var/lib/lotus/*
chown root: /var/lib/lotus

# Wait until the EBS volume is attached.
while ! grep nvme1n1 /proc/partitions; do
	echo NVME1N1 NOT PRESENT. TRYING AGAIN
	sleep 10
done

echo NVMEN1 FOUND.

# Test if EBS is already partitioned. If not, partition it.
grep nvme1n1p1 /proc/partitions
if [ $? -eq 1 ]; then
	echo INSTALLING PARTED
	apt-get update
	apt-get -y install parted
  echo PARTITIONING NVME1N1
	# Partition, format, mount
	parted /dev/nvme1n1 mklabel gpt
	parted /dev/nvme1n1 mkpart primary "0%" "100%"
	partprobe /dev/nvme1n1

	# Even with partprobe, it might take a second before a new partition appears in /proc/partitions
	sleep 30

	echo FORMATTING EBS
	mkfs.ext4 -L LOTUS -F /dev/nvme1n1p1
else
	echo PARTITION FOUND. NOT RE-PARTITIONING.
fi

echo MOUNTING EBS
echo "/dev/nvme1n1p1 /var/lib/lotus ext4 defaults 0 0" >> /etc/fstab
mount -a

echo FIXING PERMISSIONS
# Fix permissions.
chown fc: /var/lib/lotus

echo STARTING LOTUS
# Restart lotus
systemctl start lotus-daemon

echo FILEOCIN USER DATA ENDED
