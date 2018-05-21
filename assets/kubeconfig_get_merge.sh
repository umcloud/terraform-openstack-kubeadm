#!/bin/bash
src="${1:?missing src, e.g.: ubuntu@<master_ip>}"
dst="${2:?missing dst, e.g.: ./assets/kube.master.conf}"
set -xe
scp -pv -o StrictHostKeyChecking=no "${src}" "${dst}"
KUBECONFIG="~/.kube/config:${dst}" kubectl config view --flatten > ~/.kube/config
