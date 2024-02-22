#!/bin/bash

# Print ASCII art
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

# Define user names
USER1="client1"
USER2="client2"

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
for USER in $USER1 $USER2
do
  user_exists $USER
  if [ $? -eq 0 ]; then
    echo -n "Creating user ${USER}... "
    sudo adduser --gecos "" $USER >> $LOGFILE 2>&1
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

# Configure SFTP
echo -e " ${LIGHTBLUE}
 --------------------
| SFTP Configuration |
 -------------------- ${NC}"
# Backup the original sshd_config file
if [ ! -f /etc/ssh/sshd_config.bak ]; then
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
fi
# Remove trailing whitespace and comments from the sshd_config file
sudo sed -i '/^ *#/d;s/#.*//' /etc/ssh/sshd_config
# Add the SFTP configuration
if ! grep -q "^Subsystem sftp internal-sftp" /etc/ssh/sshd_config; then
  echo "Subsystem sftp internal-sftp" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
fi
for USER in $USER1 $USER2
do
  if ! grep -q "Match User $USER" /etc/ssh/sshd_config; then
    echo "Match User $USER" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
    echo "ForceCommand internal-sftp" | sudo tee -a /etc/ssh/sshd_config >> $LOGFILE 2>&1
  else
    echo -e "${YELLOW}Notice${NC}: SFTP configuration for ${BLUE}$USER${NC} already exists. To avoid potential conflicts, automatic configuration has been skipped. Please manually check and configure as necessary."
    echo -e "$(date) - User: $(whoami) - Notice: SFTP configuration for ${BLUE}$USER${NC} already exists. To avoid potential conflicts, automatic configuration has been skipped. Please manually check and configure as necessary." >> $LOGFILE
  fi
done
sudo systemctl restart ssh >> $LOGFILE 2>&1
check_success

# End of server-init.sh