#!/bin/sh
ip=${1:?missing host IP}
ssh-keygen  -f ~/.ssh/known_hosts -R ${ip}
ssh-keyscan -t ecdsa-sha2-nistp256 ${ip} >> ~/.ssh/known_hosts
