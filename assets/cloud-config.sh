#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cat << EOF > $DIR/cloud-config
[Global]
auth-url=$OS_AUTH_URL
username=$OS_USERNAME
password=$OS_PASSWORD
region=$OS_REGION_NAME
tenant-id=$OS_TENANT_ID
domain-name=$OS_PROJECT_DOMAIN_NAME

[LoadBalancer]
subnet-id=$LB_SUBNET_ID
create-monitor=yes
monitor-delay=1m
monitor-timeout=30s
monitor-max-retries=3
EOF