#!/bin/bash

#1. ID VIRTUAL MACHINES (Proxmox VMID)

ID_ISP=100
ID_HQ_RTR=101
ID_BR_RTR=102
ID_HQ_SRV=103
ID_HQ_CLI=104
ID_BR_SRV=105


# 2. INTERFACES NAME (ip a)

# --- ISP ---
ISP_IF_WAN="eth0"   # v internet (NAT)
ISP_IF_HQ="eth1"    # v storonu HQ-RTR
ISP_IF_BR="eth2"    # v storonu BR-RTR

# --- HQ-RTR ---
HQ_IF_WAN="eth0"    # v storonu ISP
HQ_IF_LAN="eth1"    # LAN

# --- BR-RTR ---
BR_IF_WAN="eth0"    # v storonu ISP
BR_IF_LAN="eth1"    # LAN сеть

# --- HQ-SRV ---
HQ_SRV_IF="ens18"

# --- HQ-CLI ----
HQ_CLI_IF="ens18"

# ---BR-SRV ---
BR_SRV_IF="ens18"

#3. УЧЕТНЫЕ ДАННЫЕ И НАСТРОЙКИ

USER_ADMIN="net_admin"
USER_SSH="sshuser"
PASS="P@ssw0rd"
TIMEZONE="Asia/Yekaterinburg"
