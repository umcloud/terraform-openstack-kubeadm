data "openstack_networking_network_v2" "public_network" {
  name = "${var.public_network}"
}

resource "openstack_compute_keypair_v2" "k8s" {
  name       = "${var.pubkey_name}"
  public_key = "${file(var.pubkey)}"
}

resource "openstack_networking_network_v2" "network_1" {
  name           = "${var.env_name}-net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name       = "${var.env_name}-subnet"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr       = "192.168.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router_1" {
  name             = "${var.env_name}-router"
  external_gateway = "${data.openstack_networking_network_v2.public_network.id}"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

resource "openstack_networking_floatingip_v2" "masterip" {
  pool = "${var.public_network}"
}

resource "openstack_compute_instance_v2" "master" {
  name        = "${var.env_name}-master"
  flavor_name = "${var.master_flavor}"
  image_name  = "${var.master_image}"
  key_pair    = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.env_name}-net"
  }

  security_groups = [
    "default",
  ]

  depends_on = [
    "openstack_networking_router_interface_v2.router_interface_1",
  ]
}

resource "openstack_compute_floatingip_associate_v2" "masterip" {
  floating_ip = "${openstack_networking_floatingip_v2.masterip.address}"
  instance_id = "${openstack_compute_instance_v2.master.id}"
  fixed_ip    = "${openstack_compute_instance_v2.master.network.0.fixed_ip_v4}"
}

resource "null_resource" "provision_master" {
  depends_on = ["openstack_compute_floatingip_associate_v2.masterip"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  provisioner "remote-exec" {
    script = "assets/bootstrap.sh"
  }

  provisioner "file" {
    source      = "assets/10-kubeadm.conf"
    destination = "/home/ubuntu/10-kubeadm.conf"
  }

  provisioner "local-exec" {
    command = "./assets/cloud-config.sh"
  }

  provisioner "file" {
    source      = "assets/cloud-config"
    destination = "/home/ubuntu/cloud-config"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf",
      "sudo mv /home/ubuntu/cloud-config /etc/kubernetes/cloud-config",
    ]
  }

  provisioner "local-exec" {
    command = "cp assets/kubeadm.conf assets/kubeadm-${openstack_compute_instance_v2.master.name}.conf"
  }

  provisioner "local-exec" {
    command = "cp assets/kubeadm.conf assets/kubeadm-${openstack_compute_instance_v2.master.name}.conf"
  }

  provisioner "local-exec" {
    command = "sed -i -e \"s/{{TOKEN}}/${var.token}/g\" assets/kubeadm-${openstack_compute_instance_v2.master.name}.conf"
  }

  provisioner "file" {
    source      = "assets/kubeadm-${openstack_compute_instance_v2.master.name}.conf"
    destination = "/home/ubuntu/kubeadm.conf"
  }

  provisioner "local-exec" {
    command = "rm assets/kubeadm-${openstack_compute_instance_v2.master.name}.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm reset && sudo kubeadm init --config=kubeadm.conf",
      "sudo chown ubuntu /etc/kubernetes/admin.conf",
    ]
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count       = "${var.worker_count}"
  name        = "${var.env_name}-worker${count.index}"
  flavor_name = "${var.worker_flavor}"
  image_name  = "${var.worker_image}"
  key_pair    = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.env_name}-net"
  }

  security_groups = [
    "default",
  ]
}

resource "null_resource" "provision_worker" {
  count = "${var.worker_count}"

  connection {
    bastion_host = "${openstack_networking_floatingip_v2.masterip.address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${element(openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4, count.index)}"
  }

  provisioner "remote-exec" {
    script = "assets/bootstrap.sh"
  }

  provisioner "file" {
    source      = "assets/10-kubeadm.conf"
    destination = "/home/ubuntu/10-kubeadm.conf"
  }

  provisioner "file" {
    source      = "assets/cloud-config"
    destination = "/home/ubuntu/cloud-config"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf",
      "sudo mv /home/ubuntu/cloud-config /etc/kubernetes/cloud-config",
    ]
  }
}

resource "null_resource" "worker_join" {
  count      = "${var.worker_count}"
  depends_on = ["null_resource.provision_worker", "null_resource.provision_master"]

  connection {
    bastion_host = "${openstack_networking_floatingip_v2.masterip.address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${element(openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm reset && sudo kubeadm join --token ${var.token} ${openstack_compute_instance_v2.master.network.0.fixed_ip_v4}:6443",
    ]
  }
}

resource "null_resource" "setup_flannel" {
  depends_on = ["null_resource.provision_master"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  provisioner "file" {
    source      = "assets/kube-flannel.yml"
    destination = "/home/ubuntu/kube-flannel.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "KUBECONFIG=/etc/kubernetes/admin.conf kubectl taint nodes --all node-role.kubernetes.io/master-",
      "KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f kube-flannel.yml",
    ]
  }

  provisioner "remote-exec" {
    script = "assets/check-flannel.sh"
  }
}