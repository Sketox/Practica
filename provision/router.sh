#!/bin/bash
# Router: habilita el reenvío de paquetes entre las subredes 10.0.1.0/24 y 10.0.2.0/24
set -e
grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p
apt-get update -y
