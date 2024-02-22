#!/bin/bash

# Define server IP and user names
SERVER_IP="server_ip"
USER1="client1"
USER2="client2"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Define log file
LOGFILE="client_setup.log"

# Function to check if a command succeeded
check_success() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Success${NC}"
  else
    echo -e "${RED}Error${NC}. Check ${LOGFILE} for more details."
  fi
}

# Update package lists
echo -n "Updating package lists... "
sudo apt update >> $LOGFILE 2>&1
check_success

# Install SSH client
echo -n "Installing SSH client... "
sudo apt install -y openssh-client >> $LOGFILE 2>&1
check_success

# Test SSH connectivity
for USER in $USER1 $USER2
do
  echo -n "Testing SSH connectivity for ${USER}... "
  ssh -o BatchMode=yes -o ConnectTimeout=5 ${USER}@${SERVER_IP} "echo 2>&1" >> $LOGFILE 2>&1 && echo "SSH connection successful"  echo "SSH connection failed"
done

# Test SFTP connectivity
for USER in $USER1 $USER2
do
  echo -n "Testing SFTP connectivity for ${USER}... "
  echo "bye" | sftp -b - ${USER}@${SERVER_IP} >> $LOGFILE 2>&1 && echo "SFTP connection successful"  echo "SFTP connection failed"
done