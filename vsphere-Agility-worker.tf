resource "vsphere_virtual_machine" "Agility_worker" {
  depends_on = ["vsphere_virtual_machine.Agility_Server1"],
  name          = "Agility11.1-Worker-plugin"
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
        ipv4_address = "130.175.93.244"
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
    "sudo sshpass -p 'M3sh@dmin!' scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null smadmin@${vsphere_virtual_machine.Agility_Server1.default_ip_address}:/home/smadmin/token /home/smadmin/",
    
    "sudo sshpass -p 'M3sh@dmin!' scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null smadmin@130.175.106.189:/home/smadmin/agility-images-11.1.0.tar.gz /home/smadmin/",
    
    "sudo sshpass -p 'M3sh@dmin!' scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null smadmin@130.175.106.189:/home/smadmin/agility-cli-11.1.0.tar.gz /home/smadmin/",
    
    "sudo sshpass -p 'M3sh@dmin!' scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null smadmin@130.175.106.189:/home/smadmin/cloud-plugin-images-11.0.2.tar.gz /home/smadmin/",
    
    "sudo docker swarm join --token $(cat /home/smadmin/token) ${vsphere_virtual_machine.Agility_Server1.default_ip_address}:2377",
    "docker image load -i agility-images-11.1.0.tar.gz",
    "docker image load -i cloud-plugin-images-11.0.2.tar.gz",
    "docker images",
    "sudo tar -xvzf /home/smadmin/agility-cli-11.1.0.tar.gz",
    "sudo /home/smadmin/swarm-scale 2",
    "sleep 30s",
    "sudo /home/smadmin/swarm-start",
    "if [ $plugin_flag=='yes' ]; then while (docker ps | grep -i 'starting');do echo 'Waiting for the Agility Service to Start';sleep 1m; done; echo 'Setting Up the Cloud Plugin Installation'; sudo sed -i -e 's/^#/ /g' agility_swarm.yml; docker stack deploy -c agility_swarm.yml agility; docker stack deploy -c cloud_plugin.yml agility; fi"
    ]
  }
}