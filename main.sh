#!/bin/bash
mkdir isc-dhcp-server
wget -qP isc-dhcp-server/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/11_init.sh
wget -qP isc-dhcp-server/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/12_routing.sh
wget -qP isc-dhcp-server/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/21_xz.sh
wget -qP isc-dhcp-server/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/22_neebu.sh
wget -qP isc-dhcp-server/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/env.sh
wget -qP isc-dhcp-server/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/lib.sh
wget -qP isc-dhcp-server/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/test1.sh
wget -qP isc-dhcp-server/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/test2.sh

bash isc-dhcp-server/11_init.sh
bash isc-dhcp-server/12_routing.sh
bash isc-dhcp-server/21_xz.sh
bash isc-dhcp-server/22_neebu.sh