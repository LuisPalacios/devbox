# coding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Español y UTF-8
ENV["LC_ALL"] = "es_ES.UTF-8"

# Version de API/Syntax del Vagrantfile
VAGRANTFILE_API_VERSION = "2" if not defined? VAGRANTFILE_API_VERSION

# Fichero de configuración para provisionar.
# Se usa aquí y desde bootstrap/bootstrap.sh
require 'yaml'
if File.file?('bootstrap/bootstrap.yaml')
  conf = YAML.load_file('bootstrap/bootstrap.yaml')
else
  raise "Me falta el fichero 'bootstrap/bootstrap.yaml' !!!"
end

# Configurar
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Ubuntu 20.10, ignorando updates
  config.vm.box = conf['boxname'] || 'generic/ubuntu2010'
  config.vm.box_check_update = false

  # Configuración con nombre, para identificar mejor la VM
  config.vm.define :coder do |coder|

    # Nombre hostname del guest
    coder.vm.hostname = conf['hostname'] || 'coder'

    # Para Libvirt
    coder.vm.provider :libvirt do |libvirt, override|
      libvirt.uri = 'qemu+unix:///system'
      libvirt.driver = "kvm"
      libvirt.host = conf['linuxhost']
      libvirt.cpus = 4
      libvirt.memory = 12288

      # Un ejemplo de Networking con IP Pública (intranet)
      # En el HOST Linux espero el bridge 'br0'
      # y que tenga asociada su interfaz Ethernet.
      #
      override.vm.network "public_network",                      
                      :dev => "br0",
                      :mode => "bridge",
                      :type => "bridge",
                    # :ip => "192.168.100.13",  Comentado para usar DHCP !!
                      :mac => "52:54:00:40:40:13"
    end
    
    # Para Virtualbox
    coder.vm.provider "virtualbox" do |vb, override|
      vb.name = conf['hostname'] || 'coder'
      vb.cpus = 4
      vb.memory = 12288

      # Forwarding solo si la VM está en VirtualBox
      # en mi propio ordenador desktop (mac o windows)
      override.vm.network :forwarded_port, guest:  7687, host:  7687, id: 'bolt'
      override.vm.network :forwarded_port, guest:  8082, host:  8082, id: 'bottle'
      override.vm.network :forwarded_port, guest:  8001, host:  8001, id: 'jupyter'
      override.vm.network :forwarded_port, guest: 27017, host: 27017, id: 'mongod'
      override.vm.network :forwarded_port, guest:  3100, host:  3100, id: 'mongoku'
      override.vm.network :forwarded_port, guest:  7474, host:  7474, id: 'neo4j'
      override.vm.network :forwarded_port, guest:  5432, host:  5432, id: 'postgres'
      override.vm.network :forwarded_port, guest:  5050, host:  5050, id: 'pgadmin'
      override.vm.network :forwarded_port, guest:  8087, host:  8087, id: 'riak-protocol-buffer'
      override.vm.network :forwarded_port, guest:  8098, host:  8098, id: 'riak-http'
      override.vm.network :forwarded_port, guest:    22, host:  2222, id: 'ssh'
    end

    # Para Parallels Desktop
    coder.vm.provider "parallels" do |prl, override|
      prl.name = conf['hostname'] || 'coder'
      prl.cpus = 4
      prl.memory = 12288
      prl.update_guest_tools = true

      # Forwarding solo si la VM está en VirtualBox
      # en mi propio ordenador desktop (mac o windows)
      override.vm.network :forwarded_port, guest:  7687, host:  7687, id: 'bolt'
      override.vm.network :forwarded_port, guest:  8082, host:  8082, id: 'bottle'
      override.vm.network :forwarded_port, guest:  8001, host:  8001, id: 'jupyter'
      override.vm.network :forwarded_port, guest: 27017, host: 27017, id: 'mongod'
      override.vm.network :forwarded_port, guest:  3100, host:  3100, id: 'mongoku'
      override.vm.network :forwarded_port, guest:  7474, host:  7474, id: 'neo4j'
      override.vm.network :forwarded_port, guest:  5432, host:  5432, id: 'postgres'
      override.vm.network :forwarded_port, guest:  5050, host:  5050, id: 'pgadmin'
      override.vm.network :forwarded_port, guest:  8087, host:  8087, id: 'riak-protocol-buffer'
      override.vm.network :forwarded_port, guest:  8098, host:  8098, id: 'riak-http'
      override.vm.network :forwarded_port, guest:    22, host:  2222, id: 'ssh'
    end

    # Incorporo el fichero de claves públicas SSH de este usuario del Host
    # al usuario 'root'. En el bootstrap se hace lo mismo con conf['usuario']
    coder.vm.provision "file", source: "bootstrap/public-keys.txt", destination: "~/.ssh/yo.pub"
    coder.vm.provision "shell", inline: <<-SHELL
                        cat /home/vagrant/.ssh/yo.pub >> /root/.ssh/authorized_keys
                        rm /home/vagrant/.ssh/yo.pub
    SHELL

    # Montar/sincronizar este directorio del proyecto con /vagrant dentro de la VM, 
    coder.vm.provider :libvirt do |libvirt|
      coder.vm.synced_folder './', '/vagrant', type: 'rsync'
    end

    # Ejecuto el script que continúa con la provisión
    coder.vm.provision:shell, path: "bootstrap/bootstrap.sh"

  end
                        
end
