#!/bin/bash

source ./lib.sh
source ./env.sh

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

CMD_NGINX='
apt-get update && apt-get install nginx -y
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
'
vm_exec $ID_ISP "$CMD_NGINX" "test proxy"
