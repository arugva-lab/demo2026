#!/bin/bash

source ./lib.sh
source ./env.sh

CMD_DOCKER='
qm set $ID_BR_SRV -scsi1 local:iso/Additional.iso,media=cdrom
sleep 30
CMD_DOCKER='
for host in /sys/class/scsi_host/host*; do
        echo "- - -" > "$host/scan"
done
apt-get install docker-engine docker-compose -y
systemctl enable --now docker
mkdir -p /mnt/add_cd
mount -t auto -o ro /dev/sr0 /mnt/add_cd
cp -r /mnt/add_cd/docker /root/docker
docker image load -i /root/docker/site_latest.tar
docker image load -i /root/docker/postgresql_latest.tar
mkdir -p testapp
touch /root/testapp/docker-compose.yaml
cat >> /root/testapp/docker-compose.yaml <<EOF
services:
  testapp:
    image: site:latest
    container_name: testapp
    restart: always
    depends_on:
      - db
    ports:
      - 8080:8000
    environment:

      DB_TYPE: postgres
      DB_HOST: db
      DB_NAME: testdb
      DB_PORT: 5432
      DB_USER: test
      DB_PASS: P@ssw0rd

  db:
    image: postgres:15-alpine
    container_name: db
    restart: always
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: test
      POSTGRES_PASSWORD: P@ssw0rd

    volumes:
      - /root/testapp/db_data:/var/lib/mysql

volumes:
  db_data:
EOF

docker compose -f /root/testapp/docker-compose.yaml up -d
'
vm_exec $ID_BR_SRV "$CMD_DOCKER" "test docker"

