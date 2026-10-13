# Pruebas automáticas del laboratorio (ejecutar desde la carpeta del repositorio):
#   powershell -ExecutionPolicy Bypass -File pruebas\verificar.ps1
# Cada prueba ejecuta un comando dentro de una VM con "vagrant ssh" y compara
# la salida con el resultado esperado. Al final muestra el resumen.

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
if (-not (Get-Command vagrant -ErrorAction SilentlyContinue)) {
    $env:Path = "C:\Program Files\Vagrant\bin;$env:Path"
}
Set-Location (Split-Path $PSScriptRoot -Parent)

# Contraseña de laboratorio definida en provision/db.sh
$mysqlApp = 'MYSQL_PWD=AppSegura#2026 mysql -h 10.0.2.10 -u app_user empresa_db'

$pruebas = @(
    # --- Conectividad y enrutamiento ---
    @{ n = 'Router: reenvío de paquetes activo (ip_forward = 1)'
       vm = 'router'; c = 'sysctl net.ipv4.ip_forward'; esperado = 'ip_forward = 1' }
    @{ n = 'Router: NAT de salida (MASQUERADE)'
       vm = 'router'; c = 'sudo iptables -t nat -S POSTROUTING'; esperado = 'MASQUERADE' }
    @{ n = 'App: ruta por defecto hacia el router 10.0.1.1'
       vm = 'app'; c = 'ip route show default'; esperado = 'default via 10.0.1.1' }
    @{ n = 'App: ping al router (10.0.1.1)'
       vm = 'app'; c = 'ping -c 2 -W 2 10.0.1.1'; esperado = ' 0% packet loss' }
    @{ n = 'App: ping a la DB en otra subred (10.0.2.10)'
       vm = 'app'; c = 'ping -c 2 -W 2 10.0.2.10'; esperado = ' 0% packet loss' }
    @{ n = 'App: salida a Internet a través del router (8.8.8.8)'
       vm = 'app'; c = 'ping -c 2 -W 3 8.8.8.8'; esperado = ' 0% packet loss' }
    @{ n = 'DB: ruta por defecto hacia el router 10.0.2.1'
       vm = 'db'; c = 'ip route show default'; esperado = 'default via 10.0.2.1' }

    # --- Configuración de seguridad de la DB ---
    @{ n = 'DB: MySQL escucha solo en la IP privada 10.0.2.10:3306'
       vm = 'db'; c = 'sudo ss -ltn sport = :3306'; esperado = '10\.0\.2\.10:3306' }
    @{ n = 'DB: firewall UFW activo (deny incoming)'
       vm = 'db'; c = 'sudo ufw status verbose'; esperado = 'Status: active[\s\S]*deny \(incoming\)' }
    @{ n = 'DB: regla 3306 permitida solo desde 10.0.1.0/24'
       vm = 'db'; c = 'sudo ufw status'; esperado = '3306/tcp\s+ALLOW\s+10\.0\.1\.0/24' }
    @{ n = "DB: usuario app_user restringido al host '10.0.1.%'"
       vm = 'db'; c = 'sudo mysql -N -e ''SELECT user,host FROM mysql.user'' | grep app_user'
       esperado = 'app_user\s+10\.0\.1\.%' }

    # --- Acceso permitido ---
    @{ n = 'App: conexión a MySQL por IP privada y lectura de datos'
       vm = 'app'; c = "$mysqlApp -B -N -e 'SELECT nombre FROM clientes'"; esperado = 'Ana Zambrano' }
    @{ n = 'App: mínimo privilegio, DROP TABLE es rechazado'
       vm = 'app'; c = "$mysqlApp -e 'DROP TABLE clientes' 2>&1"; esperado = 'ERROR 1142' }

    # --- Acceso bloqueado ---
    @{ n = 'Router (10.0.2.1): hace ping a la DB...'
       vm = 'router'; c = 'ping -c 2 -W 2 10.0.2.10'; esperado = ' 0% packet loss' }
    @{ n = '...pero NO llega al puerto 3306 (bloqueado por el firewall)'
       vm = 'router'; c = 'nc -zv -w 3 10.0.2.10 3306 2>&1; echo codigo=$?'; esperado = 'codigo=1' }
)

function Mostrar($ok, $nombre) {
    if ($ok) { Write-Host '  [OK]    ' -ForegroundColor Green -NoNewline }
    else     { Write-Host '  [FALLO] ' -ForegroundColor Red -NoNewline }
    Write-Host $nombre
}

Write-Host "`n=== Verificación del laboratorio de seguridad de la BD ===`n" -ForegroundColor Cyan
$total = 0; $bien = 0

$estado = (& vagrant status 2>&1 | Out-String)
$ok = ([regex]::Matches($estado, 'running \(vmware_desktop\)').Count -eq 3)
$total++; if ($ok) { $bien++ }; Mostrar $ok 'Las 3 VMs (router, app, db) están encendidas'

foreach ($p in $pruebas) {
    $salida = (& vagrant ssh $p.vm -c $p.c 2>&1 | Out-String)
    $ok = [regex]::IsMatch($salida, $p.esperado, 'Multiline')
    $total++; if ($ok) { $bien++ }
    Mostrar $ok $p.n
    if (-not $ok) { Write-Host ($salida.Trim() -replace '(?m)^', '          ') -ForegroundColor DarkGray }
}

# Desde Windows (fuera de las subredes) tampoco se llega al 3306
$ipDb = (& vagrant ssh db -c "ip -o -4 addr show eth0 | awk '{print `$4}' | cut -d/ -f1" 2>$null | Out-String).Trim()
$puerto = (Test-NetConnection $ipDb -Port 3306 -WarningAction SilentlyContinue).TcpTestSucceeded
$ok = (-not $puerto)
$total++; if ($ok) { $bien++ }
Mostrar $ok "Windows: el puerto 3306 de la DB ($ipDb) NO es accesible"

Write-Host "`nResultado: $bien de $total pruebas correctas`n" -ForegroundColor $(if ($bien -eq $total) { 'Green' } else { 'Yellow' })
