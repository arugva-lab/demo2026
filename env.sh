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
ISP_IF_WAN=""   # v internet (NAT)
ISP_IF_HQ=""    # v storonu HQ-RTR
ISP_IF_BR=""    # v storonu BR-RTR

# --- HQ-RTR ---
HQ_IF_WAN=""    # v storonu ISP
HQ_IF_LAN=""    # LAN

# --- BR-RTR ---
BR_IF_WAN=""    # v storonu ISP
BR_IF_LAN=""    # LAN сеть

# --- HQ-SRV ---
HQ_SRV_IF=""

# --- HQ-CLI ----
HQ_CLI_IF=""

# ---BR-SRV ---
BR_SRV_IF=""
