data "openstack_networking_network_v2" "public_network" {
  name = "${var.public_network}"
}

// Need to sort by size to cope w/snapshots having same properties
data "openstack_images_image_v2" "node_image" {
  owner = ""
  properties {
    "os_distro" = "ubuntu"
    // 18.04 deploys ok, but fails actual networking (using kube-router)
    "os_version" = "16.04"
  }
  sort_key = "size"
  sort_direction = "asc"
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
  dns_nameservers = "${var.dns_nameservers}"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr       = "192.168.185.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router_1" {
  name             = "${var.env_name}-router"
  external_network_id = "${data.openstack_networking_network_v2.public_network.id}"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

resource "openstack_networking_floatingip_v2" "masterip" {
  pool = "${var.public_network}"
}

resource "openstack_compute_secgroup_v2" "k8s_master" {
  name        = "${var.env_name}-k8s-master"
  description = "${var.env_name} - Kubernetes Master"

  rule {
    ip_protocol = "tcp"
    from_port   = "6443"
    to_port     = "6443"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "bastion" {
  name        = "${var.env_name}-bastion"
  description = "${var.env_name} - Bastion Server"

  rule {
    ip_protocol = "tcp"
    from_port   = "22"
    to_port     = "22"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "k8s" {
  name        = "${var.env_name}-k8s"
  description = "${var.env_name} - Kubernetes"

  rule {
    ip_protocol = "icmp"
    from_port   = "-1"
    to_port     = "-1"
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }

  rule {
    ip_protocol = "udp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }

  rule {
    ip_protocol = "icmp"
    from_port   = "-1"
    to_port     = "-1"
    self        = true
  }
}

resource "openstack_compute_instance_v2" "master" {
  name        = "${var.env_name}-master"
  flavor_name = "${var.master_flavor}"
  image_name  = "${data.openstack_images_image_v2.node_image.name}"
  key_pair    = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.env_name}-net"
  }

  security_groups = ["${openstack_compute_secgroup_v2.k8s_master.name}",
    "${openstack_compute_secgroup_v2.bastion.name}",
    "${openstack_compute_secgroup_v2.k8s.name}",
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

data "template_file" "kubeadm_conf" {
  template = "${file("${path.cwd}/assets/kubeadm.template.conf")}"
  vars {
     token = "${var.token}"
     int_ip = "${openstack_compute_instance_v2.master.access_ip_v4}"
     ext_ip = "${openstack_networking_floatingip_v2.masterip.address}"
     cluster_name = "${var.cluster_name}"
  }
}

resource "local_file" "kubeadm_conf" {
  content     = "${data.template_file.kubeadm_conf.rendered}"
  filename = "${path.cwd}/generated/kubeadm.conf"
}

resource "null_resource" "provision_master" {
  depends_on = [
    "openstack_compute_floatingip_associate_v2.masterip",
  ]

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

  provisioner "file" {
    source      = "${local_file.kubeadm_conf.filename}"
    destination = "/home/ubuntu/kubeadm.conf"
  }

  provisioner "remote-exec" {
    inline = [
      // "sudo kubeadm reset && sudo kubeadm init --token=${var.token} --feature-gates CoreDNS=true --pod-network-cidr=10.244.0.0/16",
      "sudo kubeadm reset && sudo kubeadm init --config=kubeadm.conf",
      "sudo chown ubuntu /etc/kubernetes/admin.conf",
      "sudo mkdir -p $HOME/.kube",
      "sudo ln -s /etc/kubernetes/admin.conf $HOME/.kube/config",
    ]
  }

  provisioner "file" {
    source      = "assets/cloud-config"
    destination = "/home/ubuntu/cloud-config"
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count       = "${var.worker_count}"
  name        = "${var.env_name}-worker${count.index}"
  flavor_name = "${var.worker_flavor}"
  image_name  = "${data.openstack_images_image_v2.node_image.name}"
  key_pair    = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.env_name}-net"
  }

  security_groups = [
    "${openstack_compute_secgroup_v2.k8s.name}",
    "default",
  ]

  // wait for master provisioning, helps debugging
  depends_on = [
    "openstack_networking_router_interface_v2.router_interface_1",
    "null_resource.provision_master"
  ]
}

resource "null_resource" "provision_worker" {
  count = "${var.worker_count}"

  connection {
    bastion_host = "${openstack_networking_floatingip_v2.masterip.address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${element(openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4, count.index)}"
    timeout      = "5m"

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
      "sudo kubeadm reset && sudo kubeadm join --token ${var.token} --discovery-token-unsafe-skip-ca-verification ${openstack_compute_instance_v2.master.network.0.fixed_ip_v4}:6443",
    ]
  }
}

resource "null_resource" "setup_cni" {
  depends_on = ["null_resource.provision_master"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

//   provisioner "file" {
//     source      = "assets/kube-flannel.yml"
//     destination = "/home/ubuntu/kube-flannel.yml"
//   }

  provisioner "remote-exec" {
    inline = [
      "KUBECONFIG=/etc/kubernetes/admin.conf kubectl taint nodes --all node-role.kubernetes.io/master-",
      // "KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f kube-flannel.yml",
      "KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml",
    ]
  }

  provisioner "remote-exec" {
    // script = "assets/check-flannel.sh"
    script = "assets/check-kube-router.sh"
  }
}

resource "null_resource" "fixup_neutron_ports" {
  depends_on = ["null_resource.provision_master", "null_resource.provision_worker"]
  provisioner "local-exec" {
    command = "./assets/kubeconfig_get_merge.sh ubuntu@${openstack_networking_floatingip_v2.masterip.address}:.kube/config ${path.cwd}/generated/kube.master.conf"
  }

  provisioner "local-exec" {
    command = "neutron port-list -c id -f value|xargs -I@ neutron port-update @ --allowed-address-pairs type=dict list=true ip_address=10.244.0.0/16"
  }
}

output "master_ip" {
  value = "${openstack_networking_floatingip_v2.masterip.address}"
}
