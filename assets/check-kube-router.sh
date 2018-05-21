#!/bin/bash

for i in `seq 1 30`; do
  echo "Checking for running kube-router container ..."
  count=$(KUBECONFIG=/etc/kubernetes/admin.conf kubectl get po --all-namespaces --no-headers | grep "kube-router" | grep Running | wc -l)
  if [ $count -gt 0 ] ; then
    echo "kube-router container is running"
    exit 0
  fi
  sleep 5
done
echo "kube-router container is still not running, aborting"
exit 1
