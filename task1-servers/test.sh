#!/bin/bash

# Define user names
USER1="client1"
USER2="client2"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Define log file
LOGFILE="setup.log"

# Function to check if a command succeeded
check_success() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Success${NC}"
  else
    echo -e "${RED}Error${NC}. Check ${LOGFILE} for more details."
  fi
}

# Create user accounts
for USER in $USER1 $USER2
do
  echo -n "Creating user ${USER}... "
  sudo adduser --disabled-password --gecos "" $USER >> $LOGFILE 2>&1
  check_success
done

# Update package lists
echo -n "Updating package lists... "
sudo apt update >> $LOGFILE 2>&1
check_success

# Install and configure NGINX
echo -n "Installing NGINX... "
sudo apt install -y nginx >> $LOGFILE 2>&1
check_success

echo -n "Starting NGINX... "
sudo systemctl start nginx >> $LOGFILE 2>&1
check_success

echo -n "Enabling NGINX to start on boot... "
sudo systemctl enable nginx >> $LOGFILE 2>&1
check_success

# Install and configure SSHD
echo -n "Installing SSHD... "
sudo apt install -y openssh-server >> $LOGFILE 2>&1
check_success

echo -n "Starting SSHD... "
sudo systemctl start ssh >> $LOGFILE 2>&1
check_success

echo -n "Enabling SSHD to start on boot... "
sudo systemctl enable ssh >> $LOGFILE 2>&1
check_success

# Configure SFTP
echo -n "Configuring SFTP... "
echo "Subsystem sftp internal-sftp" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
for USER in $USER1 $USER2
do
  echo "Match User $USER" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
  echo "ForceCommand internal-sftp" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
done
sudo systemctl restart ssh >> $LOGFILE 2>&1
check_success
