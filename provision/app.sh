#!/bin/bash
# App: cliente MySQL y curl para conectarse a la base de datos por IP privada
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y mysql-client curl
echo 'mysql-client y curl instalados'
