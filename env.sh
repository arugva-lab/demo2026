#!/bin/bash

#1. ID VIRTUAL MACHINES (Proxmox VMID)
#Virtual machine IDs can be found in the Proxmox interface near the machine name
ID_ISP=
ID_HQ_RTR=
ID_BR_RTR=
ID_HQ_SRV=
ID_HQ_CLI=
ID_BR_SRV=


#2. INTERFACES NAME (ip a)
#put interface names inside quotes

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
