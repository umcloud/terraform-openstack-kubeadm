# terraform-openstack-kubeadm

This project uses [Terraform](https://www.terraform.io/) to bootstrap a cluster on [OpenStack](https://www.openstack.org/) and installs [Kubernetes](https://kubernetes.io/) on it via [kubeadm](https://kubernetes.io/docs/getting-started-guides/kubeadm/).

## Usage

Before you can start, you need to generate a fresh token for kubeadm to use. Install kubeadm on your local machine (or somewhere else) and run `kubeadm token generate`. When you run `terraform apply`, it will ask for the kubeadm token you generated.

Make sure you sourced your `openstack.rc` file before running `terraform apply`.

By default one master and three worker nodes are bootstrapped. Please check [variables.tf](variables.tf) to see settings that you typically want to change. All scripts assume Ubuntu 16.04 as the operating system on the master and workers.

After terraform finishes, you will be able to connect to the master and run this:

```
$ export KUBECONFIG=/etc/kubernetes/admin.conf
$ kubectl get nodes
NAME              STATUS    AGE       VERSION
staging-master    Ready     3m        v1.6.4
staging-worker0   Ready     1m        v1.6.4
staging-worker1   Ready     1m        v1.6.4
staging-worker2   Ready     1m        v1.6.4
```

This project removes the taint from the master that prohibits Kubernetes from scheduling pods on the master.

## RBAC

kubeadm bootstraps clusters with activated role-based access control (RBAC). The [required ACL configuration](assets/ingress-rbac.yml) for nginx ingress is quite complicated on the first glance. You can find some discussion around it [in this ticket](https://github.com/kubernetes/ingress/issues/575). Everything ingress is deployed into a separate namespace called "nginx-ingress" and uses a fresh service account "nginx-ingress-serviceaccount".

## Non-production Usage

`kubeadm` is still in beta and will output the warning:
> WARNING: kubeadm is in beta, please do not use it for production clusters.

You should take this seriously. `kubeadm` only bootstraps a cluster with a single master so you don't have any fault tolerance.

## Networking

This project bootstraps [Flannel](https://github.com/coreos/flannel) as  a virtual network with the address space `10.244.0.0/16`. For other options check [this page](https://kubernetes.io/docs/concepts/cluster-administration/addons/).
