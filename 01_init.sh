#!/bin/bash
s#!/bin/bash

# Подгружаем настройки и библиотеку
source ./env.sh
source ./lib.sh

@@ -83,6 +82,7 @@ iface '$HQ_IF_LAN'.200 inet static
   vlan-raw-device '$HQ_IF_LAN'

auto '$HQ_IF_LAN'.999
iface '$HQ_IF_LAN'.999 inet static
iface '$HQ_IF_LAN'.999 inet static
   address 192.168.99.1/29
   vlan-raw-device '$HQ_IF_LAN'
@@ -127,55 +127,18 @@ vm_exec $ID_BR_RTR "$CMD_BR_RTR" "BR-RTR"


#   --- 2.1 HQ-SRV ---
CMD_HQ_SRV='
hostnamectl set-hostname HQ-SRV
timedatectl set-timezone '$TIMEZONE'
mkdir -p /etc/net/ifaces/'$HQ_SRV_IF'
echo "TYPE=eth\n DISABLE=no\n ONBOOT=yes\n" > /etc/net/ifaces/'$HQ_SRV_IF'/options
echo "BOOTPROTO=static" >> /etc/net/ifaces/'$HQ_SRV_IF'/options
echo "192.168.1.2/27" > /etc/net/ifaces/'$HQ_SRV_IF'/ipv4address
echo "192.168.1.1" > /etc/net/ifaces/'$HQ_SRV_IF'/ipv4route
systemctl restart network
# Настройка пользователя sshuser
useradd -m -u 2026 -s /bin/bash '$USER_SSH'
echo "'$USER_SSH':'$PASS'" | chpasswd
echo "'$USER_SSH' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'$USER_SSH'
'
vm_exec $ID_HQ_SRV "$CMD_HQ_SRV" "Настройка HQ-SRV (Alt Linux)"


# --- 2.2 BR-SRV---
CMD_BR_SRV='
hostnamectl set-hostname BR-SRV
timedatectl set-timezone '$TIMEZONE'
mkdir -p /etc/net/ifaces/'$BR_SRV_IF'
echo "TYPE=eth" > /etc/net/ifaces/'$BR_SRV_IF'/options
echo "BOOTPROTO=static\n ONBOOT=yes\n DISABLE=no" >> /etc/net/ifaces/'$BR_SRV_IF'/options
echo "BOOTPROTO=static" >> /etc/net/ifaces/'$BR_SRV_IF'/options
echo "ONBOOT=yes" >> /etc/net/ifaces/'BR_SRV_IF'/options
echo "DISABLED=no" >> /etc/net/ifaces/'BR_SRVIF'/options
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
hostnamectl set-hostname HQ-CLI-01
timedatectl set-timezone '$TIMEZONE'
mkdir -p /etc/net/ifaces/'$HQ_CLI_IF'
echo "TYPE=eth" > /etc/net/ifaces/'$HQ_CLI_IF'/options
echo "BOOTPROTO=dhcp\n ONBOOT=yes\n DISABLE=no" >> /etc/net/ifaces/'$HQ_CLI_IF'/options

systemctl restart network
'

vm_exec $ID_HQ_CLI "$CMD_HQ_CLI" "HQ-CLI"


echo ">>> MODULE 1 COMPLETE <<<"
