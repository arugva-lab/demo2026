#!/bin/bash
#set -e
source ./env.sh
source ./lib.sh
self_destruct
check_env 

#FRR ON BR-RTR & HQ-RTR
FRR_HQ_RTR='
touch /etc/apt/sources.list.d/frr.list
echo "deb [trusted=yes] https://deb.frrouting.org/frr stretch frr-8" >> /etc/apt/sources.list.d/frr.list
apt-get update --allow-insecure-repositories || true
apt-get install frr -y --allow-unauthenticated
sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
systemctl restart frr
cat > /etc/frr/frr.conf <<EOF
frr version 8.5
frr defaults traditional
hostname $(hostname)
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
interface gre1
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 demo2026
 ip ospf network broadcast
exit
!
router ospf
 passive-interface default
 no passive-interface gre1
 network 10.0.0.0/30 area 0
 network 192.168.1.0/27 area 0
 network 192.168.2.0/28 area 0
exit
!
EOF
systemctl restart frr
'
vm_exec $ID_HQ_RTR "$FRR_HQ_RTR" "FRR at HQ-RTR"

FRR_BR_RTR='
touch /etc/apt/sources.list.d/frr.list
echo "deb [trusted=yes] https://deb.frrouting.org/frr stretch frr-8" >> /etc/apt/sources.list.d/frr.list
apt-get update --allow-insecure-repositories || true
apt-get install frr -y --allow-unauthenticated
sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
systemctl restart frr
cat > /etc/frr/frr.conf <<EOF
frr version 8.5
frr defaults traditional
hostname $(hostname)
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
interface gre1
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 demo2026
 ip ospf network broadcast
exit
!
router ospf
 passive-interface default
 no passive-interface gre1
 network 10.0.0.0/30 area 0
 network 192.168.3.0/27 area 0
exit
!
EOF
systemctl restart frr
'
vm_exec $ID_BR_RTR "$FRR_BR_RTR" "FRR at BR-RTR"
# 4. DHCP ON HQ-RTR (VLAN 200)
DHCP_HQ_RTR='
apt-get install -y isc-dhcp-server
sed -i 's/INTERFACESv4=""/INTERFACESv4="'$HQ_IF_LAN'.200"/' /etc/default/isc-dhcp-server
cat > /etc/dhcp/dhcpd.conf <<EOF
option domain-name "au-team.irpo";
option domain-name-servers 192.168.1.2, 8.8.8.8;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 192.168.2.0 netmask 255.255.255.240 {
  range 192.168.2.2 192.168.2.5;
  option routers 192.168.2.1;
}
EOF
systemctl restart isc-dhcp-server
'
vm_exec $ID_HQ_RTR "$DHCP_HQ_RTR" "DHCP server at HQ-RTR"

CMD_HQ_CLI='
systemctl restart network
dhcpcd -4
'
vm_exec $ID_HQ_CLI "$CMD_HQ_CLI" "get address on HQ-CLI"

# 5. DNS AT HQ-SRV
DNS_HQ_SRV="
apt-get update && apt-get install dnsmasq -y
cat > /etc/dnsmasq.conf <<EOF
expand-hosts
localise-queries
conf-dir=/etc/dnsmasq.conf.d
interface=*
server=/au-team.irpo/192.168.3.2
server=8.8.8.8
domain=au-team. irpo
listen-address=192.168.1.2
no-resolv
no-hosts
address=/hq-rtr.au-team.irpo/192.168.1.1
ptr-record=1.1.168.192.in.addr.arpa,hq-rtr.au-team.irpo
address=/br-rtr.au-team.irpo/192.168.3.1
address=/hq-srv.au-team.irpo/192.168.1.2
ptr-record=2.1.168.192.in.addr.arpa.hq-srv.au-team.irpo
address=/hq-cli.au-team.irpo/192.168.2.2
ptr-record=2.2.168.192.in.addr.arpa,hq-cli.au-team.irpo
address=/br-srv.au-team.irpo/192.168.3.2
address=/docker.au-team.irpo/172.16.1.1
address=/web.au-team.irpo/172.16.2.1
EOF
systemctl restart dnsmasq
systemctl enable dnsmasq"
vm_exec $ID_HQ_SRV "$DNS_HQ_SRV" "DNS server HQ-SRV"

SSH_RTR="
apt update && apt install openssh-server
"

vm_exec $ID_HQ_RTR "$SSH_RTR" "SSH server HQ-RTR"
vm_exec $ID_BR_RTR "$SSH_RTR" "SSH server BR-RTR"

echo " MODULE 1-02 COMPLETE"
