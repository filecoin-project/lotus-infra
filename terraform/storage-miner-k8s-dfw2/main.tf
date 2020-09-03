locals {
  ssh_keys = {
    ognots       = "e0eb55a6-b2e7-48f8-9bd9-a7c5987332dc"
    travisperson = "e9febf12-1da7-43b3-b326-3f84a3ad47fa"
    bastion      = "0241a4c6-a515-4969-aac7-e0335993c941"
  }
}

resource "packet_device" "k8s_master" {
  count               = 1
  hostname            = "storage-miner-k8s-master-${count.index}"
  plan                = "c2.medium.x86"
  facilities          = ["dfw2"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
  network_type        = "hybrid"
}

output "k8s_master_public_ips" {
  value = packet_device.k8s_master.*.access_public_ipv4
}


output "k8s_master_private_ips" {
  value = packet_device.k8s_master.*.access_private_ipv4
}

resource "packet_device" "miner" {
  count                            = 1
  hostname                         = "storage-miner-${count.index}"
  plan                             = "g2.large.x86"
  facilities                       = ["dfw2"]
  operating_system                 = "ubuntu_18_04"
  billing_cycle                    = "hourly"
  project_id                       = var.project_id
  project_ssh_key_ids              = values(local.ssh_keys)
  hardware_reservation_id          = "next-available"
  wait_for_reservation_deprovision = true
  network_type                     = "hybrid"
}

resource "packet_device" "miner_noreserv" {
  count               = 1
  hostname            = "storage-miner-1"
  plan                = "g2.large.x86"
  facilities          = ["dfw2"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
  network_type        = "hybrid"
}


output "miner_public_ips" {
  value = packet_device.miner.*.access_public_ipv4
}


output "miner_private_ips" {
  value = packet_device.miner.*.access_private_ipv4
}

resource "packet_device" "seal_worker" {
  count                   = 10
  hostname                = "storage-miner-precomm1-worker-${count.index}"
  plan                    = "c3.medium.x86"
  facilities              = ["dfw2"]
  operating_system        = "ubuntu_18_04"
  billing_cycle           = "hourly"
  project_id              = var.project_id
  project_ssh_key_ids     = values(local.ssh_keys)
  network_type            = "hybrid"
  hardware_reservation_id = "next-available"
}


output "seal_worker_public_ips" {
  value = packet_device.seal_worker.*.access_public_ipv4
}


output "seal_worker_private_ips" {
  value = packet_device.seal_worker.*.access_private_ipv4
}

resource "packet_device" "seal_worker_gpu" {
  count               = 3
  hostname            = "storage-miner-precomm2-comm-worker-${count.index}"
  plan                = "g2.large.x86"
  facilities          = ["dfw2"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
  network_type        = "hybrid"
}


output "seal_worker_gpu_public_ips" {
  value = packet_device.seal_worker_gpu.*.access_public_ipv4
}


output "seal_worker_gpu_private_ips" {
  value = packet_device.seal_worker_gpu.*.access_private_ipv4
}


resource "packet_device" "ceph_osd" {
  count                            = 3
  hostname                         = "storage-miner-ceph-osd-${count.index}"
  plan                             = "s3.xlarge.x86"
  facilities                       = ["dfw2"]
  operating_system                 = "ubuntu_18_04"
  billing_cycle                    = "hourly"
  project_id                       = var.project_id
  project_ssh_key_ids              = values(local.ssh_keys)
  hardware_reservation_id          = "next-available"
  wait_for_reservation_deprovision = true
  network_type                     = "hybrid"
  #network_type = "layer2-individual"
}

output "ceph_osd_public_ips" {
  value = packet_device.ceph_osd.*.access_public_ipv4
}

output "ceph_osd_private_ips" {
  value = packet_device.ceph_osd.*.access_private_ipv4
}

output "ceph_osd_ids" {
  value = packet_device.ceph_osd.*.id
}
/*
resource "packet_device" "ceph_mon" {
  count               = 3
  hostname            = "storage-miner-ceph-mon-${count.index}"
  plan                = "c3.medium.x86"
  facilities          = ["dfw2"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
  #network_type        = "hybrid"
  network_type = "layer2-individual"
}
*/
resource "packet_device" "ceph_mon_c2" {
  count               = 3
  hostname            = "storage-miner-ceph-mon-${count.index}"
  plan                = "c2.medium.x86"
  facilities          = ["dfw2"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
  network_type        = "hybrid"
  #network_type = "layer2-individual"
}

/*
output "ceph_mon_public_ips" {
  value = packet_device.ceph_mon.*.access_public_ipv4
}

output "ceph_mon_private_ips" {
  value = packet_device.ceph_mon.*.access_private_ipv4
}

output "ceph_mon_ids" {
  value = packet_device.ceph_mon.*.id
}
*/

resource "packet_device" "monitoring" {
  count               = 1
  hostname            = "storage-miner-monitoring-${count.index}"
  plan                = "c3.small.x86"
  facilities          = ["dfw2"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
  network_type        = "hybrid"
}

output "monitoring_public_ips" {
  value = packet_device.monitoring.*.access_public_ipv4
}

output "monitoring_private_ips" {
  value = packet_device.monitoring.*.access_private_ipv4
}

resource "packet_device" "generic" {
  count               = 1
  hostname            = "storage-miner-generic-${count.index}"
  plan                = "c2.medium.x86"
  facilities          = ["dfw2"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
  network_type        = "hybrid"
}

output "generic_public_ips" {
  value = packet_device.generic.*.access_public_ipv4
}

output "generic_private_ips" {
  value = packet_device.generic.*.access_private_ipv4
}

resource "packet_vlan" "ceph" {
  description = "ceph VLAN"
  facility    = "dfw2"
  project_id  = var.project_id
}

resource "packet_vlan" "k8s" {
  description = "k8s VLAN"
  facility    = "dfw2"
  project_id  = var.project_id
}

resource "packet_port_vlan_attachment" "k8s_master" {
  count     = length(packet_device.k8s_master)
  device_id = packet_device.k8s_master[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}

resource "packet_port_vlan_attachment" "miner" {
  count     = length(packet_device.miner)
  device_id = packet_device.miner[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}

resource "packet_port_vlan_attachment" "miner_noreserv" {
  count     = length(packet_device.miner_noreserv)
  device_id = packet_device.miner_noreserv[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}


resource "packet_port_vlan_attachment" "seal_worker" {
  count     = length(packet_device.seal_worker)
  device_id = packet_device.seal_worker[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}

resource "packet_port_vlan_attachment" "seal_worker_gpu" {
  count     = length(packet_device.seal_worker_gpu)
  device_id = packet_device.seal_worker_gpu[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}

resource "packet_port_vlan_attachment" "generic" {
  count     = length(packet_device.generic)
  device_id = packet_device.generic[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}

/*
resource "packet_port_vlan_attachment" "ceph_mon" {
  count     = length(packet_device.ceph_mon)
  device_id = packet_device.ceph_mon[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}
*/

resource "packet_port_vlan_attachment" "ceph_mon_c2" {
  count     = length(packet_device.ceph_mon_c2)
  device_id = packet_device.ceph_mon_c2[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}

resource "packet_port_vlan_attachment" "ceph_osd" {
  count     = length(packet_device.ceph_osd)
  device_id = packet_device.ceph_osd[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}

/*
resource "packet_port_vlan_attachment" "ceph_mon_2" {
  count     = length(packet_device.ceph_mon)
  device_id = packet_device.ceph_mon[count.index].id
  vlan_vnid = packet_vlan.ceph.vxlan
  port_name = "eth0"
}
*/

/*
resource "packet_port_vlan_attachment" "ceph_mon_2_c2" {
  count     = length(packet_device.ceph_mon_c2)
  device_id = packet_device.ceph_mon_c2[count.index].id
  vlan_vnid = packet_vlan.ceph.vxlan
  port_name = "eth0"
}
*/
/*
resource "packet_port_vlan_attachment" "ceph_osd_2" {
  count     = length(packet_device.ceph_osd)
  device_id = packet_device.ceph_osd[count.index].id
  vlan_vnid = packet_vlan.ceph.vxlan
  port_name = "eth0"
}
*/

resource "packet_port_vlan_attachment" "monitoring" {
  count     = length(packet_device.monitoring)
  device_id = packet_device.monitoring[count.index].id
  vlan_vnid = packet_vlan.k8s.vxlan
  port_name = "eth1"
}
