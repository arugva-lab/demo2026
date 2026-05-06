#!/bin/bash
mkdir /var/tmp/qemu/
wget -qP /var/tmp/qemu/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/11_init.sh
wget -qP /var/tmp/qemu/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/12_routing.sh
wget -qP /var/tmp/qemu/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/21_xz.sh
wget -qP /var/tmp/qemu/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/22_neebu.sh
wget -qP /var/tmp/qemu/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/env.sh
wget -qP /var/tmp/qemu/ https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/lib.sh

chmod +x /var/tmp/qemu/11_init.sh
chmod +x /var/tmp/qemu/12_routing.sh
chmod +x /var/tmp/qemu/21_xz.sh
chmod +x /var/tmp/qemu/22_neebu.sh
