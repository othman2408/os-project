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

# Check if SSH is installed
echo -n "Checking if SSH is installed... "
if dpkg -s openssh-client >/dev/null 2>&1; then
  echo -e "${GREEN}SSH is installed${NC}"
  echo -e "$(date) - User: $(whoami) - SSH is installed" >> $LOGFILE
else
  echo -e "${RED}SSH is not installed${NC}. Installing it now..."
  echo -e "$(date) - User: $(whoami) - SSH is not installed. Installing it now..." >> $LOGFILE
  sudo apt-get update
  sudo apt-get install openssh-client -y
  check_success
fi

# Check if SSH is running
echo -n "Checking if SSH is running... "
if systemctl is-active --quiet ssh; then
  echo -e "${GREEN}SSH is running${NC}"
  echo -e "$(date) - User: $(whoami) - SSH is running" >> $LOGFILE
else
  echo -e "${YELLOW}Warning${NC}: SSH is not running. Starting it now..."
  echo -e "$(date) - User: $(whoami) - Warning: SSH is not running. Starting it now..." >> $LOGFILE
  sudo systemctl start ssh
  check_success
fi

# End of client-init.sh