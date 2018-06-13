#!/bin/sh
manifests_dir="$(dirname $(realpath $0))/../manifests"
(set -x
kubectl apply -f ${manifests_dir}/*.yaml
)

# Huristic: find "recent" users, navarrow is SPECIAL
USERS=$(find /home/* -maxdepth 0 -mtime -180 -printf "%f\n"|sed 's/navarrow/navarrow-um/;s/mauricioryan/MauricioRyan/;')

for user in ${USERS};do
  (set -x
  kubectl create ns ${user:?}
  kubectl create rolebinding --namespace=${user} --user=${user} --clusterrole=edit ${user}-role-ns-edit
  )
done

GH_TEAM=students-cd-18
kubectl create clusterrolebinding --group=${GH_TEAM:?} --clusterrole=view students-clusterrole-view --dry-run -oyaml | kubectl apply -f-
