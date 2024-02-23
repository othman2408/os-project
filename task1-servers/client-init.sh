#!/bin/bash

# Message
echo -e "
+-------------------------------------------------------------------------+
|                                                                         |
|     ____  _  _               _        ____         _                    |
|    / ___|| |(_)  ___  _ __  | |_     / ___|   ___ | |_  _   _  _ __     |
|   | |    | || | / _ \| '_ \ | __|    \___ \  / _ \| __|| | | || '_ \    |
|   | |___ | || ||  __/| | | || |_      ___) ||  __/| |_ | |_| || |_) |   |
|    \____||_||_| \___||_| |_| \__|    |____/  \___| \__| \__,_|| .__/    |
|                                                               |_|       |
|                                                                         |
+-------------------------------------------------------------------------+
"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Define log file
LOGFILE="$(dirname "$0")/client-init.log"

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

# Print SSH server status
show_ssh_status() {
  echo -e " ${LIGHTBLUE}
 -------------------
| SSH server status |
 ------------------- ${NC}"
  SSH_STATUS=$(systemctl status ssh | awk '/Active:/ {print $2}')
  if [ "$SSH_STATUS" = "active" ]; then
    echo -e "${GREEN}SSH server is active${NC}"
  else
    echo -e "${RED}SSH server is not active${NC}"
  fi

  # Show SSH server status
  SSH_IP=$(hostname -I | awk '{print $1}')
  echo -e "${LIGHTBLUE}IP address of SSH server: ${ORANGE}$SSH_IP"

  SSH_IPv6=$(hostname -I | awk '{print $2}')
  echo -e "${LIGHTBLUE}IPv6 address of SSH server: ${ORANGE}$SSH_IPv6"

  SSH_PORT=$(ss -tuln | awk '/:22/ {print $5}' | awk -F: '{print $2; exit}')
  echo -e "${LIGHTBLUE}Port of SSH server: ${ORANGE}$SSH_PORT"

  SSH_UPTIME=$(uptime -p)
  echo -e "${LIGHTBLUE}Uptime of SSH server: ${ORANGE}$SSH_UPTIME"

  SSH_SINCE=$(systemctl status ssh | awk '/since/ {print $3, $4, $5, $6, $7, $8}')
  echo -e "${LIGHTBLUE}SSH server has been active since: ${ORANGE}$SSH_SINCE"

  SSH_MAINPID=$(systemctl status ssh | awk '/Main PID:/ {print $3}')
  echo -e "${LIGHTBLUE}Main PID of SSH server: ${ORANGE}$SSH_MAINPID"

  SSH_TASKS=$(systemctl status ssh | awk '/Tasks:/ {print $2}')
  echo -e "${LIGHTBLUE}Number of tasks for SSH server: ${ORANGE}$SSH_TASKS"

  SSH_MEMORY=$(systemctl status ssh | awk '/Memory:/ {print $2}')
  echo -e "${LIGHTBLUE}Memory used by SSH server: ${ORANGE}$SSH_MEMORY"

  SSH_CGROUP=$(systemctl status ssh | awk '/CGroup:/ {print $2}')
  echo -e "${LIGHTBLUE}CGroup of SSH server: ${ORANGE}$SSH_CGROUP"
}

# Check if SSH server is installed
echo -e " ${LIGHTBLUE}
 ----------------------------------------
| Checking if SSH server is installed... |
 ---------------------------------------- ${NC}"
if dpkg -s openssh-server >/dev/null 2>&1; then
  echo -e "${GREEN}SSH server is installed${NC}"
  echo -e "$(date) - User: $(whoami) - SSH server is installed" >> $LOGFILE
else
  echo -e "${RED}SSH server is not installed${NC}. Installing it now..."
  echo -e "$(date) - User: $(whoami) - SSH server is not installed. Installing it now..." >> $LOGFILE
  sudo apt-get update
  sudo apt-get install openssh-server -y
  check_success
fi

# Check if SSH server is running
echo -e " ${LIGHTBLUE}
 --------------------------------------
| Checking if SSH server is running... |
 -------------------------------------- ${NC}"
if systemctl is-active --quiet ssh; then
  echo -e "${GREEN}SSH server is running${NC}"
  echo -e "$(date) - User: $(whoami) - SSH server is running" >> $LOGFILE
else
  echo -e "${YELLOW}Warning${NC}: SSH server is not running. Starting it now..."
  echo -e "$(date) - User: $(whoami) - Warning: SSH server is not running. Starting it now..." >> $LOGFILE
  sudo systemctl start ssh
  check_success
fi

# Priont SSH server status and information
show_ssh_status

# End of client-init.sh