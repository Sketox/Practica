#!/bin/bash
# DB: MySQL escuchando solo en la IP privada + firewall que simula el NSG
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y mysql-server

# MySQL solo escucha en la IP privada de la subred db
sed -i 's/^bind-address.*/bind-address = 10.0.2.10/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

# Interfaz de administración de Vagrant (NAT de VMware), solo para "vagrant ssh"
MGMT=$(ip -o -4 addr show | awk '$4 !~ /^(127\.|10\.0\.)/ {print $2; exit}')

# --- Simulación del NSG: solo la subred de la app puede llegar al 3306 ---
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from 10.0.1.0/24 to any port 3306 proto tcp
ufw allow in on "$MGMT" to any port 22 proto tcp
ufw --force enable

# Base de datos y usuario de prueba (el usuario solo puede entrar desde la subred app)
mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS empresa_db;
CREATE USER IF NOT EXISTS 'app_user'@'10.0.1.%' IDENTIFIED BY 'AppSegura#2026';
GRANT SELECT, INSERT, UPDATE, DELETE ON empresa_db.* TO 'app_user'@'10.0.1.%';
FLUSH PRIVILEGES;

USE empresa_db;
CREATE TABLE IF NOT EXISTS clientes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL,
  correo VARCHAR(120) NOT NULL UNIQUE
);
INSERT IGNORE INTO clientes (nombre, correo) VALUES
  ('Ana Zambrano', 'ana@empresa.com'),
  ('Luis Mendoza', 'luis@empresa.com'),
  ('María Cedeño', 'maria@empresa.com');
SQL
echo 'MySQL configurado'
