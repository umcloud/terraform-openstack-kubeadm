# terraform-openstack-kubeadm

This project uses [Terraform](https://www.terraform.io/) to bootstrap a cluster on [OpenStack](https://www.openstack.org/) and installs [Kubernetes](https://kubernetes.io/) on it via [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/).

## Usage

Before you can start, you need to generate a fresh token for kubeadm to use. Install kubeadm on your local machine (or somewhere else) and run `kubeadm token generate`. When you run `terraform apply`, it will ask for the kubeadm token you generated.

Make sure you sourced your `openstack.rc` file before running `terraform apply`. Check the [cloud-config.sh](assets/cloud-config.sh) script to find out what values are expected to exist in your environment.

By default one master and two worker nodes are bootstrapped. Please check [variables.tf](variables.tf) to see settings that you typically want to change. All scripts assume Ubuntu 16.04 as the operating system on the master and workers.

After terraform finishes, you will be able to connect to the master and run this:

```
$ export KUBECONFIG=/etc/kubernetes/admin.conf
$ kubectl get nodes
NAME              STATUS    AGE       VERSION
staging-master    Ready     3m        v1.7.5
staging-worker0   Ready     1m        v1.7.5
staging-worker1   Ready     1m        v1.7.5
```

As of now this project removes the taint from the master that prohibits Kubernetes from scheduling pods on the master. In a production setup that would not be desirable.

## Non-production Usage

`kubeadm` is still in beta and will output the warning:
> WARNING: kubeadm is in beta, please do not use it for production clusters.

You should take this seriously. `kubeadm` only bootstraps a cluster with a single master so you don't have any fault tolerance.

## Networking

This project bootstraps [Flannel](https://github.com/coreos/flannel) as  a virtual network with the address space `10.244.0.0/16`. For other options check [this page](https://kubernetes.io/docs/concepts/cluster-administration/addons/).
