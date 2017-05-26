variable "env_name" {
  default = "staging"
}

variable "pubkey" {
  default = "~/.ssh/id_rsa.pub"
}

variable "privkey" {
  default = "~/.ssh/id_rsa"
}

variable "pubkey_name" {
  default = "rtg"
}

variable "flavor" {
  default = "1C-1GB-20GB"
}

variable "image" {
  default = "Ubuntu 16.04 Xenial Xerus"
}

variable "public_network" {
  default = "ext-net"
}

variable "worker_count" {
  default = "3"
}

variable "k8s_token" {}
