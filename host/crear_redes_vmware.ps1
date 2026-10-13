# Crea en VMware Workstation las dos redes privadas de la práctica (ejecutar como Administrador).
#   vmnet2 -> 10.0.1.0/24 (subred de la aplicación)
#   vmnet3 -> 10.0.2.0/24 (subred de la base de datos)
# Son redes "host-only" sin DHCP y sin IP del host en esas subredes: solo las VMs se ven entre sí,
# igual que las subredes de una VNet de Azure.
$vnetlib = "C:\Program Files (x86)\VMware\VMware Workstation\vnetlib64.exe"
$redes = @(
  @{ vmnet = "vmnet2"; subred = "10.0.1.0" },
  @{ vmnet = "vmnet3"; subred = "10.0.2.0" }
)
foreach ($r in $redes) {
  & $vnetlib -- add adapter $r.vmnet
  & $vnetlib -- set vnet $r.vmnet mask 255.255.255.0
  & $vnetlib -- set vnet $r.vmnet addr $r.subred
  & $vnetlib -- update adapter $r.vmnet
  & $vnetlib -- remove adapter $r.vmnet   # sin adaptador del host en la subred
}

# Comprobación
Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMnetLib\VMnetConfig" | ForEach-Object {
  $c = Get-ItemProperty $_.PSPath
  [pscustomobject]@{ Red = $_.PSChildName; Subred = $c.IPSubnetAddress; Mascara = $c.IPSubnetMask }
} | Format-Table -AutoSize
