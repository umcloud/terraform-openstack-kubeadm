variable "env_name" {
  default = "k8s"
}

variable "pubkey" {
  default = "~/.ssh/cloud.key.pub"
}

variable "privkey" {
  default = "~/.ssh/cloud.key"
}

variable "pubkey_name" {
  default = "cloud"
}

variable "master_flavor" {
  default = "m1.large"
}

variable "worker_flavor" {
  default = "m1.large"
}

variable "public_network" {
  default = "ext_net"
}

variable "worker_count" {
  default = "5"
}

variable "dns_nameservers" {
  default = ["8.8.8.8"]
}

variable "cluster_name" {
  default = "kubernetes"
}

variable "os_version" {
  // NOTE(jjo): 18.04 WIP, doesn't work yet
  default = "16.04"
}

variable "token" {}

