#!/bin/bash

source ./lib.sh
source ./env.sh


qm set $ID_BR_SRV -scsi1 local:iso/Additional.iso,media=cdrom
sleep 30
CMD_DOCKER='
for host in /sys/class/scsi_host/host*; do
        echo "- - -" > "$host/scan"
done
apt-get update && apt-get install docker-engine docker-compose -y
systemctl enable --now docker
mkdir -p /mnt/add_cd
mount -t auto -o ro /dev/sr1 /mnt/add_cd
mkdir -p /root/docker/
cp -r /mnt/add_cd/docker /root/
docker image load -i /root/docker/site_latest.tar
docker image load -i /root/docker/mariadb_latest.tar
mkdir -p /root/testapp/
touch /root/testapp/docker-compose.yaml
cat > /root/testapp/docker-compose.yaml <<EOF
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

      DB_TYPE: maria
      DB_HOST: db
      DB_NAME: testdb
      DB_PORT: 3306
      DB_USER: test
      DB_PASS: P@ssw0rd

  db:
    image: mariadb:10.11
    container_name: db
    restart: always
    environment:
      MARIADB_DATABASE: testdb
      MARIADB_USER: test
      MARIADB_PASSWORD: P@ssw0rd
      MARIADB_ROOT_PASSWORD: P@ssw0rd

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

#static translate ports
CMD_BR_RTR='
iptables -t nat -A PREROUTING -d 172.16.2.2 -p tcp --dport 8080 -j DNAT --to-destination 192.168.3.2:8080
iptables -t nat -A PREROUTING -d 172.16.2.2 -p tcp --dport 2026 -j DNAT --to-destination 192.168.3.2:2026
iptables-save > /etc/iptables.rules
'
vm_exec $ID_BR_RTR "$CMD_BR_RTR" "test br"

CMD_HQ_RTR='
iptables -t nat -A PREROUTING -d 172.16.1.2 -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.2:8080
iptables -t nat -A PREROUTING -d 172.16.1.2 -p tcp --dport 2026 -j DNAT --to-destination 192.168.1.2:2026
iptables-save > /etc/iptables.rules
'
vm_exec $ID_HQ_RTR "$CMD_HQ_RTR" "test hq"


#revers proxy

#switch port web 80 > 8080
CMD_HQ_SRV="
sed -i 's/Listen 80/Listen 8080/' /etc/httpd2/conf/ports-available/http.conf
systemctl restart httpd2
"
vm_exec $ID_HQ_SRV "$CMD_HQ_SRV" "swithing port web"

CMD_NGINX="
apt-get update && apt-get install nginx apache2-utils -y
htpasswd -bc /etc/nginx/.htpasswd WEB 'P@ssw0rd'
chmod 644 /etc/nginx/.httpasswd
rm -f /etc/nginx/sites-available/default
touch /etc/nginx/sites-available/default
cat >> /etc/nginx/sites-available/default <<EOF
server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/html;
        server_name web/au-team.irpo;
        location / {
                        proxy_pass http://172.16.1.2:8080;
			auth_basic 'Web-Authorization';
			auth_basic_user_file /etc/nginx/.htpasswd;
                }
}

server {
        listen 80;
        server_name docker.au-team.irpo;
        location / {
                        proxy_pass http://172.16.2.2:8080;
        }
}
EOF
systemctl restart nginx
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
"

vm_exec $ID_ISP "$CMD_NGINX" "test proxy and auth"



# ----- VELIKIY YANDEX BROWSER -----
CMD_O_VELIKIY_YANDEX_BROWSER='
apt-get update && apt-get install yandex-browser-stable -y
'

vm_exec $ID_HQ_CLI "$CMD_O_VELIKIY_YANDEX_BROWSER" "INSTALL BEST OF THE BEST BROWSER EVER"
