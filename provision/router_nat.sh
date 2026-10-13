#!/bin/bash
# Router: NAT de salida para que app y db puedan descargar paquetes.
# Se ejecuta en cada arranque porque las reglas de iptables no son persistentes.
set -e
WAN=$(ip route | awk '/^default/ {print $5; exit}')
iptables -t nat -C POSTROUTING -o "$WAN" -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -o "$WAN" -j MASQUERADE
echo "NAT de salida por $WAN"
