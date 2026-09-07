#!/bin/bash
#
# LEGACY / DEPRECATED
# This host bootstrap script is a historical MSM-based input, not the target
# Autism Up Minecraft Server Manager architecture. Do not use it to provision
# production. See docs/legacy/legacy-implementation-inventory.md and
# docs/architecture/minecraft-server-manager-plan.md. Removal requires M8-004.
#

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

sudo adduser auoperator
sudo usermod -aG sudo auoperator
sudo usermod -aG minecraft auoperator
