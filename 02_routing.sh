#!/bin/bash

source ./env.sh
source ./lib.sh

# --- HQ-RTR ---

# GRE
CMD_HQ_RTR='
cat >> /etc/network/interfaces << EOF

auto gre0
iface gre0 inet static
    address 10.10.10.1
    netmask 255.255.255.252
    mode gre
    endpoint 172.16.2.2
    "local" 172.16.1.2
    ttl 255
EOF
ifup gre0

# NAT 
iptables -t nat -A POSTROUTING -o '$HQ_IF_WAN' -j MASQUERADE
touch /etc/iptables.rules
iptables-save > /etc/iptables.rules
'
vm_exec $ID_HQ_RTR "$CMD_HQ_RTR" "GRE & NAT on HQ-RTR"

# --- BR-RTR ---

CMD_BR_RTR='
#GRE
cat >> /etc/network/interfaces << EOF
auto gre0
iface gre0 inet static
    address 10.10.10.2
    netmask 255.255.255.252
    mode gre
    endpoint 172.16.1.2
    "local" 172.16.2.2
    ttl 255
EOF

ifup gre0

#NAT
iptables -t nat -A POSTROUTING -o '$BR_IF_WAN' -j MASQUERADE
touch /etc/iptables.rules
iptables-save > /etc/iptables.rules
'
vm_exec $ID_BR_RTR "$CMD_BR_RTR"  "GRE & NAT on BR-RTR"

#FRR ON BR-RTR & HQ-RTR
CMD_FRR='
setup_frr() {
    local VMID=$1
    local ROUTER_ID=$2
    local LAN_NET=$3

    cat > tmp_frr.sh <<EOF
apt-get update && apt-get install frr -y
sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons

cat >> /etc/frr/frr.conf <<EOT
frr defaults traditional
hostname $(hostname)
log syslog informational
!
interface gre0
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 demo2026key
!
router ospf
 ospf router-id $ROUTER_ID
 passive-interface $HQ_IF_WAN
 passive-interface $BR_IF_WAN
EOF

for net in $NETWORKS; do
    echo " network \$net area 0" >> /etc/frr/frr.conf
done

cat >> /etc/frr/frr.conf <<EOT
 network $GRE_NET/30 area 0
!
line vty
!
EOT

systemctl restart frr
EOF
'
    vm_exec $VMID "$CMD_FRR" "FRR at VM $VMID"


setup_frr $ID_HQ_RTR "1.1.1.1" "$HQ_LAN_NET"
setup_frr $ID_BR_RTR "2.2.2.2" "$BR_LAN_NET"

# 4. DHCP ON HQ-RTR (VLAN 200)

CMD_FRR='
cat > tmp_dhcp.sh <<EOF
apt-get install -y isc-dhcp-server
sed -i 's/INTERFACESv4=""/INTERFACESv4="eth1.200"/' /etc/default/isc-dhcp-server

cat >> /etc/dhcp/dhcpd.conf <<EOT
option domain-name "au-team.irpo";
option domain-name-servers 192.168.1.2;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 192.168.2.0 netmask 255.255.255.224 {
  range 192.168.2.2 192.168.2.30;
  option routers 192.168.2.1;
}
EOT
systemctl restart isc-dhcp-server
EOF
'
vm_exec $ID_HQ_RTR "$CMD_FRR" "DHCP server at HQ-RTR"

# 5. DNS AT HQ-SRV
CMD_DNS_HQ_SRV='
cat > tmp_dns.sh <<EOF
apt-get update && apt-get install bind bind-utils -y
sed -i 's/listen-on { 127.0.0.1; };/listen-on { any; };/' /etc/bind/named.conf
sed -i 's/allow-query     { localhost; };/allow-query     { any; };/' /etc/bind/named.conf
sed -i '/recursion yes;/a \        forwarders { 8.8.8.8; };' /etc/bind/named.conf

cat >> /etc/bind/named.conf <<EOT

zone "au-team.irpo" IN {
    type master;
    file "master/au-team.irpo.zone";
};
EOT
mkdir -p /var/lib/bind/master
cat > /var/lib/bind/master/au-team.irpo.zone <<EOT
\$TTL 86400
@   IN  SOA ns.au-team.irpo. admin.au-team.irpo. (
            2023101001 ; Serial
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

EOT

chown root:named /var/lib/bind/master/au-team.irpo.zone
systemctl enable --now named
EOF
'
vm_exec $ID_HQ_SRV "$CMD_DNS_HQ_SRV" "DNS server at HQ-SRV"
rm tmp_*.sh

echo " MODULE 1-02 COMPLETE"
