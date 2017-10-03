#!/bin/bash

sudo apt-get update
#sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo sh -c "cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF"
sudo apt-get update
sudo apt-get install -y docker-engine
sudo apt-get install -y --no-install-recommends kubeadm=1.7.5-00
sudo mkdir -p /etc/systemd/system/kubelet.service.d
