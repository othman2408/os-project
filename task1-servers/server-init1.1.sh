#!/bin/bash

# Message for server-init.sh
echo -e "
+------------------------------------------------------------------------------------+
|                                                                                    |
|    ____                                          ____         _                    |
|   / ___|   ___  _ __ __   __ ___  _ __  ___     / ___|   ___ | |_  _   _  _ __     |
|   \___ \  / _ \| '__|\ \ / // _ \| '__|/ __|    \___ \  / _ \| __|| | | || '_ \    |
|    ___) ||  __/| |    \ V /|  __/| |   \__ \     ___) ||  __/| |_ | |_| || |_) |   |
|   |____/  \___||_|     \_/  \___||_|   |___/    |____/  \___| \__| \__,_|| .__/    |
|                                                                          |_|       |
|                                                                                    |
+------------------------------------------------------------------------------------+
"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
LIGHTBLUE='\033[0;36m'
NC='\033[0m' # No Color

# Define log file
LOGFILE="$(dirname "$0")/server-init.log"

# Function to check if a command succeeded
check_success() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Success${NC}"
    echo -e "$(date) - User: $(whoami) - Success" >> $LOGFILE
  else
    echo -e "${RED}Error${NC}. Check ${LOGFILE} for more details."
    echo -e "$(date) - User: $(whoami) - Error. Check ${LOGFILE} for more details." >> $LOGFILE
  fi
}

# Function to check if a user exists
user_exists() {
  if id -u "$1" >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning${NC}: User $1 already exists. Skipping."
    echo -e "$(date) - User: $(whoami) - Warning: User $1 already exists. Skipping." >> $LOGFILE
    return 1
  fi
  return 0
}

# Create user accounts
echo -e " ${LIGHTBLUE}
 ------------------------
| Creating User Accounts |
 ------------------------ ${NC}"
echo -n "Enter username for the first user: "
read USER1
echo -n "Enter username for the second user: "
read USER2

for USER in $USER1 $USER2
do
  user_exists $USER
  if [ $? -eq 0 ]; then
    echo -n "Creating user ${USER}... "
    echo
    echo -n "Enter password for ${USER}: "
    read -s PASSWORD
    PASSWORD=$(openssl passwd -1 "$PASSWORD")
    sudo useradd -m -p $PASSWORD $USER >> $LOGFILE 2>&1
    check_success
  fi
done

# Update package lists
echo -e "${LIGHTBLUE}
 ------------------------
| Updating Package Lists |
 ------------------------ ${NC}"
echo -n "Updating package lists..."
echo
sudo apt update >> $LOGFILE 2>&1
check_success

# Install and configure NGINX
echo -e " ${LIGHTBLUE}
 --------------------------------------
| NGINX Installation and Configuration |
 -------------------------------------- ${NC}"
if ! dpkg -s nginx >/dev/null 2>&1; then
  echo -n "Installing NGINX... "
  sudo apt install -y nginx >> $LOGFILE 2>&1
  check_success
else
  echo -e "${YELLOW}Warning${NC}: NGINX is already installed. Skipping."
  echo -e "$(date) - User: $(whoami) - Warning: NGINX is already installed. Skipping." >> $LOGFILE
fi

echo -n "Starting NGINX... "
sudo systemctl start nginx >> $LOGFILE 2>&1
check_success

echo -n "Enabling NGINX to start on boot... "
sudo systemctl enable nginx >> $LOGFILE 2>&1
check_success

# Display NGINX server information
echo -e " ${LIGHTBLUE}
 --------------------------
| NGINX Server Information |
 -------------------------- ${NC}"
if systemctl is-active --quiet nginx; then
  echo -e "${GREEN}NGINX is running${NC}"
  echo "Server Name: $(hostname)"
  echo "Server IPv4: $(hostname -I | awk '{print $1}')"
  echo "Server IPv6: $(hostname -I | awk '{print $2, $3}')"
  echo -e "$(date) - User: $(whoami) - NGINX is running" >> $LOGFILE
  echo "Server Name: $(hostname)" >> $LOGFILE
  echo "Server IPv4: $(hostname -I | awk '{print $1}')" >> $LOGFILE
  echo "Server IPv6: $(hostname -I | awk '{print $2, $3}')" >> $LOGFILE
fi

# Install and configure SSHD
echo -e " ${LIGHTBLUE}
 -------------------------------------
| SSHD Installation and Configuration |
 ------------------------------------- ${NC}"
if ! dpkg -s openssh-server >/dev/null 2>&1; then
  echo -n "Installing SSHD... "
  sudo apt install -y openssh-server >> $LOGFILE 2>&1
  check_success
else
  echo -e "${YELLOW}Warning${NC}: SSHD is already installed. Skipping."
  echo -e "$(date) - User: $(whoami) - Warning: SSHD is already installed. Skipping." >> $LOGFILE
fi

echo -n "Starting SSHD... "
sudo systemctl start ssh >> $LOGFILE 2>&1
check_success

echo -n "Enabling SSHD to start on boot... "
sudo systemctl enable ssh >> $LOGFILE 2>&1
check_success

# Configure SSHD for SFTP
echo -e " ${LIGHTBLUE}
 -----------------------------
| SSHD Configuration for SFTP |
 ----------------------------- ${NC}"
for USER in $USER1 $USER2
do
  echo -n "Configuring SSHD for SFTP for user ${USER}... "
  echo "Match User $USER" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
  echo "    AllowTCPForwarding yes" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
  echo "    X11Forwarding yes" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
  check_success
done

# Restart SSHD
echo -n "Restarting SSHD... "
sudo systemctl restart ssh >> $LOGFILE 2>&1
check_success

# Display SSHD server information
echo -e " ${LIGHTBLUE}
 -------------------------
| SSHD Server Information |
 ------------------------- ${NC}"
if systemctl is-active --quiet ssh; then
  echo -e "${GREEN}SSHD is running${NC}"
  echo "Server Name: $(hostname)"
  echo "Server IPv4: $(hostname -I | awk '{print $1}')"
  echo "Server IPv6: $(hostname -I | awk '{print $2, $3}')"
  echo -e "$(date) - User: $(whoami) - SSHD is running" >> $LOGFILE
  echo "Server Name: $(hostname)" >> $LOGFILE
  echo "Server IPv4: $(hostname -I | awk '{print $1}')" >> $LOGFILE
  echo "Server IPv6: $(hostname -I | awk '{print $2, $3}')" >> $LOGFILE
fi

# End of server-init.sh
