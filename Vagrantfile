# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# LEGACY / DEPRECATED
# This Vagrant environment is a historical MSM-based development input, not the
# target Autism Up Minecraft Server Manager architecture. Do not use it to
# provision production. See docs/legacy/legacy-implementation-inventory.md and
# docs/architecture/minecraft-server-manager-plan.md. Removal requires M8-004.
#

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/focal64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
  config.vm.network :forwarded_port, guest: 25565, host: 25565


  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
    vb.memory = "2048"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive  
    apt-get update
    apt-get -y upgrade
    git config --global user.name "Nicholas Hatch"
    git config --global user.email "nicholas@thehatchcloud.org"
    apt-get -y install openjdk-17-jre-headless screen rsync zip jq
    wget https://git.io/6eiCSg -O /etc/msm.conf
    mkdir -p /opt/msm
    useradd minecraft --home /opt/msm
    chsh -s /bin/bash minecraft
    chown -R minecraft:minecraft /opt/msm
    chmod -R 775 /opt/msm
    mkdir /dev/shm/msm
    chown -R minecraft:minecraft /dev/shm/msm
    chmod -R 775 /dev/shm/msm
    wget https://git.io/J1GAxA -O /etc/init.d/msm
    chmod 755 /etc/init.d/msm
    update-rc.d msm defaults 99 10
    ln -s /etc/init.d/msm /usr/local/bin/msm
    msm update
    wget https://git.io/pczolg -O /etc/cron.d/msm
    service cron reload
    msm update --noinput
    mkdir /opt/build_tools
    chown -R minecraft:minecraft /opt/build_tools
    chmod -R 775 /opt/build_tools
    curl -o /opt/build_tools/BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
    
  SHELL
end
