#!/bin/bash

source ./lib.sh
source ./env.sh

qm set $ID_HQ_SRV -scsi3 local:iso/Additional.iso,media=cdrom

CMD_WEB="
for host in /sys/class/scsi_host/host; do
	echo '- - -' > '$host/scan'
done

apt-get update && apt-get install lamp-server -y
mkdir -p /mnt/add_cd/
mount -t auto -o ro /dev/sr1 /mnt/add_cd
cp /mnt/add_cd/web/index.php /var/www/html
cp /mnt/add_cd/web/logo.png /var/www/html
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
sed -i 's/.*username.*/$username = \'web\'/' /var/www/html/index.php
sed -i 's/.*password.*/$password = \'P@ssw0rd\'/' /var/www/html/index.php
sed -i 's/.*dbname.*/$dbname = \'webdb\'/' /var/www/html/index.php
#echo 'DocumentRoot/var/www/html >> /etc/httpd2/conf/sites-available/default.conf
#sed -i 
systemctl enable --now mariadb
mariadb -u root <<EOF
CREATE DATABASE webdb;
CREATE USER 'web'@'localhost' IDENTIFIED BY 'P@ssw0rd';
GRANT ALL PRIVILEGES ON webdb.* TO 'web'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
mariadb -u root webdb < /mnt/add_cd/web/dump.sql
systemctl enable --now httpd2
"
vm_exec $ID_HQ_SRV "$CMD_WEB" "test web"
