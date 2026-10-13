# -*- mode: ruby -*-
# Práctica: configuración de seguridad en una base de datos (App + DB + Router)
# Adaptación local de la guía de Azure usando Vagrant + VMware Workstation.
#
#   Subred de la aplicación (equivale a la subnet "app" de la VNet) -> 10.0.1.0/24  (vmnet2)
#   Subred de la base de datos (equivale a la subnet "db" de la VNet) -> 10.0.2.0/24 (vmnet3)
#   El router hace el papel del enrutamiento interno que Azure da por defecto.

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provider "vmware_desktop" do |v|
    v.allowlist_verified = true   # la box bento ya trae los ajustes VMX necesarios
  end

  # ---------- VM ROUTER ----------
  config.vm.define "router" do |r|
    r.vm.hostname = "router"
    r.vm.network "private_network", ip: "10.0.1.1"   # interfaz en la subred app
    r.vm.network "private_network", ip: "10.0.2.1"   # interfaz en la subred db
    r.vm.provider "vmware_desktop" do |v|
      v.memory = 1024
      v.cpus = 1
    end
    r.vm.provision "shell", path: "provision/router.sh"
    r.vm.provision "shell", path: "provision/router_nat.sh", run: "always"
  end

  # ---------- VM APP ----------
  config.vm.define "app" do |a|
    a.vm.hostname = "app"
    a.vm.network "private_network", ip: "10.0.1.10"
    a.vm.provider "vmware_desktop" do |v|
      v.memory = 1024
      v.cpus = 1
    end
    a.vm.provision "shell", path: "provision/ruta_default.sh", args: ["10.0.1.1"], run: "always"
    a.vm.provision "shell", path: "provision/app.sh"
  end

  # ---------- VM DB ----------
  config.vm.define "db" do |d|
    d.vm.hostname = "db"
    d.vm.network "private_network", ip: "10.0.2.10"
    d.vm.provider "vmware_desktop" do |v|
      v.memory = 1024
      v.cpus = 1
    end
    d.vm.provision "shell", path: "provision/ruta_default.sh", args: ["10.0.2.1"], run: "always"
    d.vm.provision "shell", path: "provision/db.sh"
    # MySQL escucha solo en 10.0.2.10: se reinicia en cada arranque por si
    # levantó antes de que la interfaz privada tuviera su IP.
    d.vm.provision "shell", inline: "systemctl restart mysql", run: "always"
  end
end
