#!/bin/bash
#
# LEGACY / DEPRECATED
# This Google Cloud provisioning script is a historical MSM-based input, not the
# target DigitalOcean architecture. Do not use it to provision production. See
# docs/legacy/legacy-implementation-inventory.md and
# docs/architecture/minecraft-server-manager-plan.md. Removal requires M8-004.
#

## VARIABLES
PROJECT_ID="autismupminecraft"
IP_NAME="au-minecraft-ip"
INSTANCE_NAME="au-minecraft-2023070202"
REGION="us-east4"
ZONE="us-east4-a"
MACHINE_TYPE="e2-standard-4"
MACHINE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
DISK_SIZE=200GB
DISK_TYPE="pd-ssd"

# Set the project ID
gcloud config set project $PROJECT_ID

# Reserve a public IP address
echo "1 - Provisioning a public IP address"
gcloud compute addresses create $IP_NAME --region=$REGION

echo "Waiting for 5 seconds while the IP address provisions"
sleep 5

# Create the vm
echo "2 - Provisioning the vm"
gcloud compute instances create $INSTANCE_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --image-family=$MACHINE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --boot-disk-size=$DISK_SIZE \
    --boot-disk-type=$DISK_TYPE \
    --network-tier=PREMIUM \
    --address=$IP_NAME

gcloud compute instances add-tags $INSTANCE_NAME --zone=$ZONE --tags=ssh
gcloud compute instances add-tags $INSTANCE_NAME --zone=$ZONE --tags=https
gcloud compute instances add-tags $INSTANCE_NAME --zone=$ZONE --tags=webmin
gcloud compute instances add-tags $INSTANCE_NAME --zone=$ZONE --tags=minecraft

# Set the firewall rules
echo "Setting the firewall rules"
gcloud compute firewall-rules create allow-tag-ssh \
    --allow=tcp:22 \
    --network=default \
    --source-ranges=0.0.0.0/0 \
    --target-tags=ssh

gcloud compute firewall-rules create allow-tag-web-https \
    --allow=tcp:443 \
    --network=default \
    --source-ranges=0.0.0.0/0 \
    --target-tags=https

gcloud compute firewall-rules create allow-tag-webmin \
    --allow=tcp:10000 \
    --network=default \
    --source-ranges=0.0.0.0/0 \
    --target-tags=webmin

gcloud compute firewall-rules create allow-tag-minecraft \
    --allow=tcp:25565 \
    --network=default \
    --source-ranges=0.0.0.0/0 \
    --target-tags=minecraft

echo "Done!"
