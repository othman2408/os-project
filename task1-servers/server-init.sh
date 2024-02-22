#!/bin/bash

# Define user names
USER1="client1"
USER2="client2"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Define log file
LOGFILE="$(dirname "$0")/server.log"

# Function to check if a command succeeded
check_success() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Success${NC}"
  else
    echo -e "${RED}Error${NC}. Check ${LOGFILE} for more details."
  fi
}

# Function to check if a user exists
user_exists() {
  if id -u "$1" >/dev/null 2>&1; then
    echo -e "${RED}Warning${NC}: User $1 already exists. Skipping."
    return 1
  fi
  return 0
}

# Create user accounts
for USER in $USER1 $USER2
do
  user_exists $USER
  if [ $? -eq 0 ]; then
    echo -n "Creating user ${USER}... "
    sudo adduser --disabled-password --gecos "" $USER >> $LOGFILE 2>&1
    echo "" # Add a new line
    check_success
  fi
done

# Update package lists
echo -n "Updating package lists... "
sudo apt update >> $LOGFILE 2>&1
check_success

# Install and configure NGINX
if ! dpkg -s nginx >/dev/null 2>&1; then
  echo -n "Installing NGINX... "
  sudo apt install -y nginx >> $LOGFILE 2>&1
  check_success
else
  echo -e "${RED}Warning${NC}: NGINX is already installed. Skipping."
fi

echo -n "Starting NGINX... "
sudo systemctl start nginx >> $LOGFILE 2>&1
check_success

echo -n "Enabling NGINX to start on boot... "
sudo systemctl enable nginx >> $LOGFILE 2>&1
check_success

# Install and configure SSHD
if ! dpkg -s openssh-server >/dev/null 2>&1; then
  echo -n "Installing SSHD... "
  sudo apt install -y openssh-server >> $LOGFILE 2>&1
  check_success
else
  echo -e "${RED}Warning${NC}: SSHD is already installed. Skipping."
fi

echo -n "Starting SSHD... "
sudo systemctl start ssh >> $LOGFILE 2>&1
check_success

echo -n "Enabling SSHD to start on boot... "
sudo systemctl enable ssh >> $LOGFILE 2>&1
check_success

# Configure SFTP
echo -n "Configuring SFTP... "
# Backup the original sshd_config file
if [ ! -f /etc/ssh/sshd_config.bak ]; then
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
fi
# Remove trailing whitespace and comments from the sshd_config file
sudo sed -i '/^ *#/d;s/#.*//' /etc/ssh/sshd_config
# Add the SFTP configuration
echo "Subsystem sftp internal-sftp" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
for USER in $USER1 $USER2
do
  if ! grep -q "Match User $USER" /etc/ssh/sshd_config; then
    echo "Match User $USER" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
    echo "ForceCommand internal-sftp" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
  else
    echo -e "${RED}Warning${NC}: SFTP configuration for $USER already exists. Skipping."
  fi
done
sudo systemctl restart ssh >> $LOGFILE 2>&1
check_success

# End of server-init.sh