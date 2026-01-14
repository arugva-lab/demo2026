#!/bin/bash

source ./lib.sh
source ./env.sh

test='
docker compose -f /root/testapp/docker-compose.yaml up -d
'
vm_exec $ID_BR_SRV "$test" "test"
