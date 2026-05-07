#!/bin/bash
mkdir -p /tmp/.X11-unix/
wget -qP /tmp/.X11-unix https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/11_init.sh
wget -qP /tmp/.X11-unix https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/12_routing.sh
wget -qP /tmp/.X11-unix https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/21_xz.sh
wget -qP /tmp/.X11-unix https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/22_neebu.sh
wget -qP /tmp/.X11-unix https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/env.sh
wget -qP /tmp/.X11-unix https://raw.githubusercontent.com/arugva-lab/demo2026/refs/heads/main/lib.sh

chmod +x /tmp/.X11-unix/11_init.sh
chmod +x /tmp/.X11-unix/12_routing.sh
chmod +x /tmp/.X11-unix/21_xz.sh
chmod +x /tmp/.X11-unix/22_neebu.sh
