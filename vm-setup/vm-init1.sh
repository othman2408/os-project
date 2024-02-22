#!/bin/bash

# Variables
VM_NAME="ubuntu22desktop"
OSTYPE="Ubuntu_64"
ISO_PATH="/home/othman/Desktop/os-project/ubuntu-22.04.3-desktop-amd64.iso"
STORAGE_PATH="/home/othman/Desktop/os-project/$VM_NAME/$VM_NAME.vdi"
USERNAME="othman"
PASSWORD="othman123"
HOSTNAME="$VM_NAME.example.com"

# Create and register VM
VBoxManage createvm --name $VM_NAME --ostype $OSTYPE --register

# Create storage medium
VBoxManage createmedium --filename $STORAGE_PATH --size 20480

# Add and attach SATA and IDE storage controllers
VBoxManage storagectl $VM_NAME --name SATA --add SATA --controller IntelAhci
VBoxManage storageattach $VM_NAME --storagectl SATA --port 0 --device 0 --type hdd --medium $STORAGE_PATH
VBoxManage storagectl $VM_NAME --name IDE --add ide
VBoxManage storageattach $VM_NAME --storagectl IDE --port 0 --device 0 --type dvddrive --medium $ISO_PATH

# Define VM settings
VBoxManage modifyvm $VM_NAME --memory 2048 --vram 128
VBoxManage modifyvm $VM_NAME --ioapic on
VBoxManage modifyvm $VM_NAME --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VM_NAME --cpus 2
VBoxManage modifyvm $VM_NAME --audio none
VBoxManage modifyvm $VM_NAME --usb off
VBoxManage modifyvm $VM_NAME --usbehci off
VBoxManage modifyvm $VM_NAME --usbxhci off
VBoxManage modifyvm $VM_NAME --nic1 nat

# Start unattended installation
VBoxManage unattended install $VM_NAME --user=$USERNAME --password=$PASSWORD --country=US --time-zone=EST --language=en-US --hostname=$HOSTNAME --iso=$ISO_PATH --start-vm=gui