#!/bin/sh
manifests_dir=${1:?}
kubectl apply -f ${manifests_dir}/*.yaml

# Huristic: find "recent" users
USERS=$(find /home/* -maxdepth 0 -mtime -180 -printf "%f\n")

for user in ${USERS};do
  kubectl create ns ${user:?}
  kubectl create rolebinding --namespace=${user} --user=${user} --clusterrole=edit ${user}-role-ns-edit
done

GH_TEAM=students-cd-18
kubectl create clusterrolebinding --group=${GH_TEAM:?} --clusterrole=view students-clusterrole-view --dry-run -oyaml | kubectl apply -f-
