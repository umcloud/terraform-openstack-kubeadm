#!/bin/bash

for i in `seq 1 30`; do
  echo "Checking for running flannel container ..."
  count=$(KUBECONFIG=/etc/kubernetes/admin.conf kubectl get po --all-namespaces --no-headers | grep "kube-flannel" | grep Running | wc -l)
  if [ $count -gt 0 ] ; then
    echo "Flannel container is running"
    exit 0
  fi
  sleep 5
done
echo "Flannel container is still not running, aborting"
exit 1
