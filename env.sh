#!/bin/bash

#1. ID ВИРТУАЛЬНЫХ МАШИН (Proxmox VMID)

ID_ISP=100
ID_HQ_RTR=101
ID_BR_RTR=102
ID_HQ_SRV=103
ID_HQ_CLI=104
ID_BR_SRV=105


# 2. НАЗВАНИЯ ИНТЕРФЕЙСОВ (ip a)

# --- ISP ---
ISP_IF_WAN="eth0"   # В интернет (NAT)
ISP_IF_HQ="eth1"    # В сторону HQ-RTR
ISP_IF_BR="eth2"    # В сторону BR-RTR

# --- HQ-RTR ---
HQ_IF_WAN="eth0"    # В сторону ISP
HQ_IF_LAN="eth1"    # Внутренняя сеть

# --- BR-RTR ---
BR_IF_WAN="eth0"    # В сторону ISP
BR_IF_LAN="eth1"    # Внутренняя сеть

# --- SERVERS / CLIENTS ---
HQ_SRV_IF="ens18"
HQ_CLI_IF="ens18"
BR_SRV_IF="ens18"

#3. УЧЕТНЫЕ ДАННЫЕ И НАСТРОЙКИ

USER_ADMIN="net_admin"
USER_SSH="sshuser"
PASS="P@ssw0rd"
TIMEZONE="Asia/Yekaterinburg"
