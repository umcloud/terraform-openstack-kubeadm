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

variable "master_flavor" {
  default = "2C-4GB-20GB"
}

variable "master_image" {
  default = "Ubuntu 16.04 Xenial Xerus"
}

variable "worker_flavor" {
  default = "2C-4GB-20GB"
}

variable "worker_image" {
  default = "Ubuntu 16.04 Xenial Xerus"
}

variable "public_network" {
  default = "ext-net"
}

variable "worker_count" {
  default = "2"
}

variable "token" {}