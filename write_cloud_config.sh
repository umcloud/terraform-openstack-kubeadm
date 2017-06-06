#!/bin/bash

cat << EOF > assets/cloud-config
[Global]
auth-url=$OS_AUTH_URL
username=$OS_USERNAME
password=$OS_PASSWORD
region=$OS_REGION_NAME
tenant-name=$OS_TENANT_NAME
EOF
