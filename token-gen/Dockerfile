FROM fedora:rawhide

COPY kubernetes.repo /etc/yum.repos.d

RUN yum update -y && yum install -y kubeadm
ENTRYPOINT kubeadm token generate
