#!/bin/bash

set -xe
sudo apt-get update -qy
sudo apt-get upgrade -qy
sudo apt-get install -qy apt-transport-https curl software-properties-common conntrack

# NEither kubernetes nor docker-ce pkgs for bionic as of May/2018, force xenial
# release=$(lsb_release -cs)
os_release=xenial

# MTU'isms ftW
iface=$(ip r get 8.8.8.8| sed -nr 's/.* dev (\S+) .*/\1/p')
mtu=$(ip li show ${iface:?}|sed -nr 's/.* mtu (\S+) .*/\1/p')

echo "iface=${iface:?} mtu=${mtu:?}"
sudo install -d /etc/docker
sudo tee /etc/docker/daemon.json << EOF
{
  "mtu": ${mtu}
}
EOF

sudo tee /etc/udev/rules.d/71-docker-mtu.rules << EOF
SUBSYSTEM=="net", ACTION=="add", NAME=="e*", RUN+="/sbin/iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS  --clamp-mss-to-pmtu -o %k"
SUBSYSTEM=="net", ACTION=="add", NAME=="e*", RUN+="/sbin/iptables -I OUTPUT  -p tcp --tcp-flags SYN,RST SYN -j TCPMSS  --clamp-mss-to-pmtu -o %k"
#SUBSYSTEM=="net", ACTION=="add", NAME=="kube-bridge", RUN+="/sbin/ip link set mtu ${mtu} dev '%k'"
EOF
sudo udevadm control -R
sudo udevadm trigger --attr-match=subsystem=net -c add

# docker-ce
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${os_release} stable"
sudo apt-get update -qy
sudo apt-get install -qy docker-ce

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo sh -c "cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-${os_release} main
EOF"
sudo apt-get update -qy
#sudo apt-get install -qy docker-engine
sudo apt-get install -qy --no-install-recommends kubeadm
sudo mkdir -p /etc/systemd/system/kubelet.service.d
