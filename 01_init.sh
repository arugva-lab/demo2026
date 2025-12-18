#!/bin/bash

source ./env.sh
source ./lib.sh

#--- 1.1 ISP --- 
CMD_ISP_NET='
hostnamectl set-hostname isp.au-team.irpo
timedatectl set-timezone '$TIMEZONE'
cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

#WAN
auto '$ISP_IF_WAN'
iface '$ISP_IF_WAN' inet dhcp

#LAN BR
auto '$ISP_IF_BR'
iface '$ISP_IF_BR' inet static
	address 172.16.2.1/28
#LAN HQ
auto '$ISP_IF_HQ'
iface '$ISP_IF_HQ' inet static
	address 172.16.1.1/28
EOF

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

#NAT
iptables -t nat -A POSTROUTING -o '$ISP_IF_WAN' -j MASQUERADE
touch /etc/iptables.rules
iptables-save >> /etc/iptables.rules

systemctl restart networking
'
CMD_ISP_USER='
useradd -m -s /bin/bash '$USER_ADMIN'
echo "'$USER_ADMIN' ALL=(ALL) NOPASSWD:ALL" > /etc/sudors.d/'$USER_ADMIN'
'
vm_exec $ID_ISP "$CMD_ISP_NET" "ISP net"
vm_exec $ID_ISP "$CMD_ISP_NET" "ISP user"

# --- 1.2 HQ-RTR ---
CMD_HQ_RTR='
hostnamectl set-hostname hq-rtr.au-team.irpo
timedatectl set-timezone '$TIMEZONE'
modprobe 8021q
echo "8021q" >> /etc/modules

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto '$HQ_IF_WAN'
iface '$HQ_IF_WAN' inet static
	address 172.16.1.2/28
	gateway 172.16.1.1

auto '$HQ_IF_LAN'
iface '$HQ_IF_LAN' inet manual

auto '$HQ_IF_LAN'.100
iface '$HQ_IF_LAN'.100 inet static
	address 192.168.1.1/27
	vlan-raw-device '$HQ_IF_LAN'

auto '$HQ_IF_LAN'.200
iface '$HQ_IF_LAN'.200 inet static
	address 192.168.2.1/27
	vlan-raw-device '$HQ_IF_LAN'

auto '$HQ_IF_LAN'.999
iface '$HQ_IF_LAN'.999 inet static
   address 192.168.99.1/29
   vlan-raw-device '$HQ_IF_LAN'
EOF

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
systemctl restart networking

useradd -m -s /bin/bash '$USER_ADMIN'
echo "'$USER_ADMIN':'$PASS'" | chpasswd
echo "'$USER_ADMIN' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'$USER_ADMIN'
'
vm_exec $ID_HQ_RTR "$CMD_HQ_RTR" "HQ-RTR"

#  --- BR-RTR ---
CMD_BR_RTR='
hostnamectl set-hostname br-rtr.au-team.irpo
timedatectl set-timezone '$TIMEZONE'
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto '$BR_IF_WAN'
iface '$BR_IF_WAN' inet static
	address 172.16.2.2/28
	gateway 172.16.2.1

auto '$BR_IF_LAN'
iface '$BR_IF_LAN' inet static
	address 192.168.3.1/28
EOF

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
systemctl restart networking

useradd -m -s /bin/bash '$USER_ADMIN'
echo "'$USER_ADMIN':'PASS'" | chpasswd
echo "'$USER_ADMIN' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'$USER_ADMIN'
'
vm_exec $ID_BR_RTR "$CMD_BR_RTR" "BR-RTR"

#   --- 2.1 HQ-SRV ---
CMD_HQ_SRV='
hostnamectl set-hostname hq-srv.au-team.irpo
timedatectl set-timezone '$TIMEZONE'
mkdir -p /etc/net/ifaces/'$HQ_SRV_IF'.100
echo "TYPE=eth" > /etc/net/ifaces/'$HQ_SRV_IF'/options
echo "DISABLED=no" >> /etc/net/ifaces/'$HQ_SRV_IF'/options
echo "ONBOOT=yes" >> /etc/net/ifaces/'$HQ_SRV_IF'/options
echo "BOOTPROTO=static" >> /etc/net/ifaces/'$HQ_SRV_IF'/options
echo "TYPE=vlan" >> /etc/net/ifaces/'$HQ_SRV_IF'.100/options
echo "DISABLED=no" >> /etc/net/ifaces/'$HQ_SRV_IF'.100/options
echo "HOST='$HQ_SRV_IF'" >> /etc/net/ifaces/'$HQ_SRV_IF'.100/options
echo "VID=100" >> /etc/net/ifaces/'$HQ_SRV_IF'.100/options
echo "192.168.1.2/27" > /etc/net/ifaces/'$HQ_SRV_IF'.100/ipv4address
echo "192.168.1.1" > /etc/net/ifaces/'$HQ_SRV_IF'.100/ipv4route
systemctl restart network
useradd -m -u 2026 -s /bin/bash '$USER_SSH'
echo "'$USER_SSH':'$PASS'" | chpasswd
echo "'$USER_SSH' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'$USER_SSH'
'
vm_exec $ID_HQ_SRV "$CMD_HQ_SRV" "HQ-SRV"


# --- 2.2 BR-SRV---
CMD_BR_SRV='
hostnamectl set-hostname br-srv.au-team.irpo
timedatectl set-timezone '$TIMEZONE'
mkdir -p /etc/net/ifaces/'$BR_SRV_IF'
echo "TYPE=eth" > /etc/net/ifaces/'$BR_SRV_IF'/options
echo "BOOTPROTO=static" >> /etc/net/ifaces/'$BR_SRV_IF'/options
echo "ONBOOT=yes" >> /etc/net/ifaces/'$BR_SRV_IF'/options
echo "DISABLED=no" >> /etc/net/ifaces/'$BR_SRVIF'/options
echo "192.168.3.2/28" > /etc/net/ifaces/'$BR_SRV_IF'/ipv4address
echo "192.168.3.1" > /etc/net/ifaces/'$BR_SRV_IF'/ipv4route

systemctl restart network

useradd -m -u 2026 -s /bin/bash '$USER_SSH'
echo "'$USER_SSH':'$PASS'" | chpasswd
echo "'$USER_SSH' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'$USER_SSH'
'

vm_exec $ID_BR_SRV "$CMD_BR_SRV" "BR-SRV"

# --- 3.1 HQ-CLI ---

CMD_HQ_CLI='
hostnamectl set-hostname hq-cli.au-team.irpo
timedatectl set-timezone '$TIMEZONE'
mkdir -p /etc/net/ifaces/'$HQ_CLI_IF'
echo "DISABLED=no" >> /etc/net/ifaces/'$HQ_CLI_IF'/options
mkdir -p /etc/net/ifaces/'$HQ_CLI_IF'.200
echo "TYPE=vlan" > /etc/net/ifaces/'$HQ_CLI_IF'.200/options
echo "BOOTPROTO=dhcp" >> /etc/net/ifaces/'$HQ_CLI_IF'.200/options
echo "ONBOOT=yes" >> /etc/net/ifaces/'$HQ_CLI_IF'.200/options
echo "DISABLED=no" >> /etc/net/ifaces/'$HQ_CLI_IF'.200/options
echo "VID=200" >> /etc/net/ifaces/'$HQ_CLI_IF'.200/options
echo "HOST='$HQ_CLI_IF'" >> /etc/net/ifaces/'$HQ_CLI_IF'.200/options
systemctl restart network
'

vm_exec $ID_HQ_CLI "$CMD_HQ_CLI" "HQ-CLI"


echo ">>> MODULE 1 COMPLETE <<<"
