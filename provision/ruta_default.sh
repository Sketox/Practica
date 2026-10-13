#!/bin/bash
# Ruta por defecto hacia el router de la subred (10.0.1.1 en app, 10.0.2.1 en db)
set -e
ip route replace default via "$1"
ip route
