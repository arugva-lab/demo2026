#!/bin/bash

# Подгружаем настройки и библиотеку
source ./env.sh
source ./lib.sh

echo ">>> ЗАПУСК МОДУЛЯ 1 (Astra + Alt Linux) <<<"

#ЧАСТЬ 1: ASTRA LINUX (Роутеры ISP, HQ-RTR, BR-RTR)
#   --- 1.1 ISP (Astra) ---
CMD_ISP_NET='
hostnamectl set-hostname ISP
timedatectl set-timezone '$TIMEZONE'

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

# WAN (DHCP)
auto '$ISP_IF_WAN'
iface '$ISP_IF_WAN' inet dhcp

# LAN to HQ
auto '$ISP_IF_HQ'
iface '$ISP_IF_HQ' inet static
    address 172.16.1.1/28

# LAN to BR
auto '$ISP_IF_BR'
iface '$ISP_IF_BR' inet static
    address 172.16.2.1/28
EOF

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# NAT
iptables -t nat -A POSTROUTING -o '$ISP_IF_WAN' -j MASQUERADE
apt-get install -y iptables-persistent 2>/dev/null
netfilter-persistent save

systemctl restart networking
'

CMD_ISP_USER='
useradd -m -s /bin/bash '$USER_ADMIN'
echo "'$USER_ADMIN':'$PASS'" | chpasswd
echo "'$USER_ADMIN' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'$USER_ADMIN'
'

vm_exec $ID_ISP "$CMD_ISP_NET" "Настройка сети ISP (Astra)"
vm_exec $ID_ISP "$CMD_ISP_USER" "Создание админа на ISP"


# --- 1.2 HQ-RTR (Astra) ---
CMD_HQ_RTR='
hostnamectl set-hostname HQ-RTR
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

# Trunk Port
auto '$HQ_IF_LAN'
iface '$HQ_IF_LAN' inet manual

# VLANs
auto '$HQ_IF_LAN'.100
iface '$HQ_IF_LAN'.100 inet static
    address 10.10.10.1/27
    vlan-raw-device '$HQ_IF_LAN'

auto '$HQ_IF_LAN'.200
iface '$HQ_IF_LAN'.200 inet static
    address 10.10.20.1/27
    vlan-raw-device '$HQ_IF_LAN'

auto '$HQ_IF_LAN'.999
iface '$HQ_IF_LAN'.999 inet static
    address 10.10.99.1/29
    vlan-raw-device '$HQ_IF_LAN'
EOF

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
systemctl restart networking
'
# (Юзера добавляем так же, опустим для краткости, он стандартный)
vm_exec $ID_HQ_RTR "$CMD_HQ_RTR" "Настройка HQ-RTR (Astra)"


# --- 1.3 BR-RTR (Astra) ---
CMD_BR_RTR='
hostnamectl set-hostname BR-RTR
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
    address 10.20.10.1/28
EOF

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
systemctl restart networking
'
vm_exec $ID_BR_RTR "$CMD_BR_RTR" "Настройка BR-RTR (Astra)"


#   --- 2.1 HQ-SRV (Alt Server) ---
# Настройка статики через Etcnet
CMD_HQ_SRV='
hostnamectl set-hostname HQ-SRV
timedatectl set-timezone '$TIMEZONE'

# 1. Создаем папку интерфейса
mkdir -p /etc/net/ifaces/'$HQ_SRV_IF'

# 2. Файл options (Тип и режим загрузки)
echo "TYPE=eth" > /etc/net/ifaces/'$HQ_SRV_IF'/options
echo "BOOTPROTO=static" >> /etc/net/ifaces/'$HQ_SRV_IF'/options

# 3. Файл ipv4address (IP/Mask)
echo "10.10.10.10/27" > /etc/net/ifaces/'$HQ_SRV_IF'/ipv4address

# 4. Файл ipv4route (Шлюз по умолчанию)
echo "default via 10.10.10.1" > /etc/net/ifaces/'$HQ_SRV_IF'/ipv4route

# 5. Применяем настройки (в Alt это сервис network)
systemctl restart network

# Настройка пользователя sshuser (Alt)
# Группа sudo в Alt может называться wheel, но мы даем права через файл в sudoers.d
useradd -m -u 2026 -s /bin/bash '$USER_SSH'
echo "'$USER_SSH':'$PASS'" | chpasswd
# Создаем файл sudoers (в Alt путь такой же)
echo "'$USER_SSH' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'$USER_SSH'
'

vm_exec $ID_HQ_SRV "$CMD_HQ_SRV" "Настройка HQ-SRV (Alt Linux)"


# --- 2.2 BR-SRV (Alt Server) ---
CMD_BR_SRV='
hostnamectl set-hostname BR-SRV
timedatectl set-timezone '$TIMEZONE'

mkdir -p /etc/net/ifaces/'$BR_SRV_IF'
echo "TYPE=eth" > /etc/net/ifaces/'$BR_SRV_IF'/options
echo "BOOTPROTO=static" >> /etc/net/ifaces/'$BR_SRV_IF'/options
echo "10.20.10.10/28" > /etc/net/ifaces/'$BR_SRV_IF'/ipv4address
echo "default via 10.20.10.1" > /etc/net/ifaces/'$BR_SRV_IF'/ipv4route

systemctl restart network

useradd -m -u 2026 -s /bin/bash '$USER_SSH'
echo "'$USER_SSH':'$PASS'" | chpasswd
echo "'$USER_SSH' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'$USER_SSH'
'

vm_exec $ID_BR_SRV "$CMD_BR_SRV" "Настройка BR-SRV (Alt Linux)"


# ==============================================================================
# ЧАСТЬ 3: ALT LINUX WORKSTATION (Клиент HQ-CLI)
# Используем /etc/net/ifaces (DHCP Client)
# ==============================================================================

# --- 3.1 HQ-CLI (Alt Workstation) ---
# Задание требует получения IP по DHCP (когда поднимем DHCP на роутере)
CMD_HQ_CLI='
hostnamectl set-hostname HQ-CLI-01
timedatectl set-timezone '$TIMEZONE'

mkdir -p /etc/net/ifaces/'$HQ_CLI_IF'

# Для DHCP нужны только options
echo "TYPE=eth" > /etc/net/ifaces/'$HQ_CLI_IF'/options
echo "BOOTPROTO=dhcp" >> /etc/net/ifaces/'$HQ_CLI_IF'/options

# Удаляем статику если была
rm -f /etc/net/ifaces/'$HQ_CLI_IF'/ipv4address
rm -f /etc/net/ifaces/'$HQ_CLI_IF'/ipv4route

systemctl restart network
'

vm_exec $ID_HQ_CLI "$CMD_HQ_CLI" "Настройка HQ-CLI (Alt DHCP)"


echo ">>> ✅ МОДУЛЬ 1 ГОТОВ (Сеть настроена на Astra и Alt) <<<"
