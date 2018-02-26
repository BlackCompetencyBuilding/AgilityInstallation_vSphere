provider "vsphere" {
    user = "${var.vsphere_user}"
    password = "${var.vsphere_password}"
    vsphere_server = "${var.vsphere_host}"
    allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "lab"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore2"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
    name = "Agility-Pool"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "agility-appliance-11.0.1-el7-x86_64_new"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "Agility_Server1" {
  name          = "Agility11.1-Server1-plugin"
  num_cpus      = 2
  memory        = 4096
  datastore_id = "${data.vsphere_datastore.datastore.id}"
  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    customize {
    linux_options {
        host_name = "Appliance"
        domain    = "localdomain"
      }
    network_interface {
        ipv4_address = "130.175.93.243"
      }

      ipv4_gateway = "130.175.93.129"
    }
        }
  disk {
    label = "disk0"
    size  = "200"
    thin_provisioned = "true"
  }
  connection {
    host = "${self.default_ip_address}"
    type     = "ssh"
    user     = "smadmin"
    password = "M3sh@dmin!"
  }
  provisioner "remote-exec" {
    inline = [
    "plugin_flag=${var.plugin_install}",
    "sudo firewall-cmd --permanent --zone=trusted --change-interface=docker_gwbridge",
    "sudo firewall-cmd --zone=public --permanent --add-masquerade",
    "sudo firewall-cmd --zone=public --permanent --add-port=2377/tcp",
    "sudo firewall-cmd --zone=public --permanent --add-port=2376/tcp",
    "sudo firewall-cmd --zone=public --permanent --add-port=7946/tcp",
    "sudo firewall-cmd --zone=public --permanent --add-port=7946/udp",
    "sudo firewall-cmd --zone=public --permanent --add-port=4789/udp",
    "sudo firewall-cmd --zone=trusted --permanent --add-masquerade",
    "sudo firewall-cmd --zone=trusted --permanent --add-port=2377/tcp",
    "sudo firewall-cmd --zone=trusted --permanent --add-port=2376/tcp",
    "sudo firewall-cmd --zone=trusted --permanent --add-port=7946/tcp",
    "sudo firewall-cmd --zone=trusted --permanent --add-port=7946/udp",
    "sudo firewall-cmd --zone=trusted --permanent --add-port=4789/udp",
    "sudo firewall-cmd --reload",
    "sudo systemctl stop docker",
    "sudo systemctl start docker",
    "sudo sshpass -p 'M3sh@dmin!' scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null smadmin@130.175.106.189:/home/smadmin/agility-images-11.1.0.tar.gz /home/smadmin/",
    "sudo sshpass -p 'M3sh@dmin!' scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null smadmin@130.175.106.189:/home/smadmin/cloud-plugin-images-11.0.2.tar.gz /home/smadmin/",
    "docker swarm init",
    "docker swarm join-token manager",
    "sudo docker swarm join-token --quiet manager > /home/smadmin/token",
    "docker image load -i agility-images-11.1.0.tar.gz",
    "docker image load -i cloud-plugin-images-11.0.2.tar.gz",
    "docker images"
    ]
  }
}