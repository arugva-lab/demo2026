#!/bin/bash

source ./lib.sh
source ./env.sh


qm set $ID_BR_SRV -scsi1 local:iso/Additional.iso,media=cdrom
sleep 30
CMD_DOCKER='
for host in /sys/class/scsi_host/host*; do
        echo "- - -" > "$host/scan"
done
apt-get install docker-engine docker-compose -y
systemctl enable --now docker
mkdir -p /mnt/add_cd
mount -t auto -o ro /dev/sr1 /mnt/add_cd
mkdir -p /root/docker/
cp -r /mnt/add_cd/docker /root/
docker image load -i /root/docker/site_latest.tar
docker image load -i /root/docker/postgresql_latest.tar
mkdir -p /root/testapp/
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


qm set $ID_HQ_SRV -scsi3 local:iso/Additional.iso,media=cdrom

CMD_WEB="
for host in /sys/class/scsi_host/host*; do
        echo '- - -' > '$host/scan'
done

apt-get update && apt-get install lamp-server -y
mkdir -p /mnt/add_cd/
mount -t auto -o ro /dev/sr1 /mnt/add_cd
cp /mnt/add_cd/web/index.php /var/www/html
cp /mnt/add_cd/web/logo.png /var/www/html
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
sed -i 's/\r//g' /var/www/html/index.php
sed -i 's/\$username = \"user\"/\$username = \"web\";/' /var/www/html/index.php
sed -i 's/\$password = \"password\"/\$password = \"P@ssw0rd\";/' /var/www/html/index.php
sed -i 's/\$dbname = \"db\"/\$dbname = \"webdb\";/' /var/www/html/index.php
systemctl enable --now mariadb
sleep 22
mariadb -u root <<'EOF'
CREATE DATABASE webdb;
CREATE USER 'web'@'localhost' IDENTIFIED BY 'P@ssw0rd';
GRANT ALL PRIVILEGES ON webdb.* TO 'web'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
mariadb -u root webdb < /mnt/add_cd/web/dump.sql
systemctl enable --now httpd2
"
vm_exec $ID_HQ_SRV "$CMD_WEB" "test web"
