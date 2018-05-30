#!/bin/bash

LB_SUBNET_ID=${1:?missing nodes subnet-id}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ -z "$OS_TENANT_ID" ] && OS_TENANT_ID=$(openstack token issue -f value -c project_id)
: ${OS_TENANT_ID:?}
cat << EOF > $DIR/cloud-config
[Global]
auth-url=$OS_AUTH_URL
username=$OS_USERNAME
password=$OS_PASSWORD
region=$OS_REGION_NAME
tenant-name=$OS_TENANT_NAME
tenant-id=$OS_TENANT_ID
domain-name=$OS_PROJECT_DOMAIN_NAME

[LoadBalancer]
subnet-id=$LB_SUBNET_ID
create-monitor=yes
monitor-delay=1m
monitor-timeout=30s
monitor-max-retries=3
EOF
