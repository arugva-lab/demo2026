#!/bin/bash

source ./env.sh
source ./lib.sh

# --- HQ-RTR ---

# GRE
GRE_HQ_RTR='
cat >> /etc/network/interfaces << EOF

auto gre1
iface gre1 inet static
    address 10.10.10.1
    netmask 255.255.255.252
    pre-up ip tunnel add gre1 mode gre remote 172.16.2.2 local 172.16.1.2 ttl 255
    up ip link set gre1 up
    post-down ip tunnel del gre1
EOF
ifup gre1
'
vm_exec $ID_HQ_RTR "$GRE_HQ_RTR" "GRE & NAT on HQ-RTR"

# --- BR-RTR ---

GRE_BR_RTR='
#GRE
cat >> /etc/network/interfaces << EOF
auto gre1
iface gre1 inet static
    address 10.10.10.2
    netmask 255.255.255.252
    pre-up ip tunnel add gre1 mode gre remote 172.16.1.2 local 172.16.2.2 ttl 255
    post-down ip tunnel del gre1
EOF
ifup gre1
'
vm_exec $ID_BR_RTR "$GRE_BR_RTR"  "GRE & NAT on BR-RTR"

#FRR ON BR-RTR & HQ-RTR
#FRR_HQ_RTR='
#apt-get update && apt-get install frr -y
#sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
#
#cat >> /etc/frr/frr.conf <<EOF
#frr defaults traditional
#hostname $(hostname)
#log syslog informational
#!
#interface gre1
# ip ospf authentication message-digest
# ip ospf message-digest-key 1 md5 demo2026key
#!
#router ospf
# ospf router-id 1.1.1.1
#EOF
#systemctl restart frr
#
#'
#vm_exec $ID_HQ_RTR "$FRR_HQ_RTR" "FRR at HQ-RTR"

# 4. DHCP ON HQ-RTR (VLAN 200)
DHCP_HQ_RTR='
apt-get update && apt-get install -y isc-dhcp-server
sed -i 's/INTERFACESv4=""/INTERFACESv4="'$HQ_IF_LAN'.200"/' /etc/default/isc-dhcp-server
rm -f /etc/dhcp/dhcpd.conf
touch /etc/dhcp/dhcpd.conf
cat >> /etc/dhcp/dhcpd.conf <<EOF
option domain-name "au-team.irpo";
option domain-name-servers 192.168.1.2, 8.8.8.8;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 192.168.2.0 netmask 255.255.255.224 {
  range 192.168.2.2 192.168.2.30;
  option routers 192.168.2.1;
}
EOF
systemctl restart isc-dhcp-server
'
vm_exec $ID_HQ_RTR "$DHCP_HQ_RTR" "DHCP server at HQ-RTR"

# 5. DNS AT HQ-SRV
DNS_HQ_SRV="
touch /etc/apt/sources.list.d/demo2026.list
echo 'rpm [p10] http://mirror.yandex.ru/altlinux p10/branch/x86_64 classic gostcrypto' >> /etc/apt/sources.list.d/demo2026.list
echo 'rpm [p10] http://mirror.yandex.ru/altlinux p10/branch/x86_64-i586 classic' >> /etc/apt/sources.list.d/demo2026.list
echo 'rpm [p10] http://mirror.yandex.ru/altlinux p10/branch/noarch classic' >> /etc/apt/sources.list.d/demo2026.list
apt-get update && apt-get install bind bind-utils -y
sed -i 's/listen-on { 127.0.0.1; };/listen-on { any; };/' /etc/bind/named.conf
sed -i 's/allow-query     { localhost; };/allow-query     { any; };/' /etc/bind/named.conf
sed -i '/recursion yes;/a \        forwarders { 8.8.8.8; };' /etc/bind/named.conf

cat >> /etc/bind/local.conf <<'EOF'

zone \"au-team.irpo\" {
    type master;
    file \"/etc/bind/db.au-team.irpo\";
};
zone \"1.168.192.in-addr.arpa\" {
    type master;
    file \"/etc/bind/db.1.168.192.in-addr.arpa\";
};
zone \"2.168.192.in-addr.arpa\" {
    type master;
    file \"/etc/bind/db.2.168.192.in-addr.arpa\";
};
EOF
touch /etc/bind/db.au-team.irpo
cat > /etc/bind/db.au-team.irpo <<'EOF'
\$TTL 86400
@   IN  SOA ns.au-team.irpo. admin.au-team.irpo. (
            2025020103 ; Serial
            3600       ; Refresh
            1800       ; Retry
            604800     ; Expire
            86400 )    ; Minimum

@       IN  NS      ns.au-team.irpo.
ns      IN  A       192.168.1.2
hq-srv  IN  A       192.168.1.2
br-srv  IN  A       192.168.3.2
hq-rtr  IN  A       192.168.1.1
br-rtr  IN  A       192.168.3.1
hq-cli	IN  A       192.168.2.2
web     IN  A       172.16.1.1
docker  IN  A       172.16.2.1
EOF
touch /etc/bind/db.1.168.192.in-addr.arpa
cat > /etc/bind/db.1.168.192.in-addr.arpa <<'EOF'
\$TTL 1D
@  IN  SOA ns.au-team.irpo admin.au-team.irpo (
           2025291603 ; Serial
           3600       ; Refresh
           1800       ; Retry
           604800     ; Expire
           86400 )    ; Minimum
        IN  NS      ns.au-team.irpo.
1       IN  PTR     hq-rtr.au-team.irpo.
2       IN  PTR     hq-srv.au-team.irpo.
EOF
touch /etc/bind/db.2.168.192.in-addr.arpa
cat > /etc/bind/db.2.168.192.in-addr.arpa <<'EOF'
\$TTL 1D
@  IN  SOA ns.au-team.irpo admin.au-team.irpo (
           2025291603 ; Serial
           3600       ; Refresh
           1800       ; Retry
           604800     ; Expire
           86400 )    ; Minimum
        IN  NS      ns.au-team.irpo.
1       IN  PTR     hq-rtr.au-team.irpo.
2       IN  PTR     hq-cli.au-team.irpo.
EOF
chown root:named /etc/bind/db.au-team.irpo
chown root:named /etc/bind/db.1.168.192.in-addr.arpa
chown root:named /etc/bind/db.2.168.192.in-addr.arpa
systemctl enable --now bind
systemctl restart bind
"
vm_exec $ID_HQ_SRV "$DNS_HQ_SRV" "DNS server HQ-SRV"
echo " MODULE 1-02 COMPLETE"
