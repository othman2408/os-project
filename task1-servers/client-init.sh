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

# Define colors for better output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Define log file path
LOGFILE="$(dirname "$0")/client-setup.log"

# Function to check if SSH server is installed
check_ssh_installed() {
    echo -e " ${LIGHTBLUE}
 ----------------------------
| SSH server installation... |
 ---------------------------- ${NC}"
    if dpkg -s openssh-server &>>"$LOGFILE"; then
        echo -e "${GREEN}SSH server is installed${NC}"
        echo -e "$(date) - User: $(whoami) - SSH server is installed" >> "$LOGFILE"
        check_ssh_enabled
    else
        echo -e "${YELLOW}Warning${NC}: SSH server is not installed."
        echo -e "$(date) - User: $(whoami) - Warning: SSH server is not installed." >> "$LOGFILE"
        echo -e "${YELLOW}Installing SSH server...${NC}"
        sudo apt-get update &>>"$LOGFILE" && sudo apt-get install -y openssh-server &>>"$LOGFILE"
        check_success
        check_ssh_enabled
    fi
}

# Function to check if SSH server is enabled
check_ssh_enabled() {
    echo -e " ${LIGHTBLUE}
 -------------------
| Enable SSH server |
 ------------------- ${NC}"
    if systemctl is-enabled --quiet sshd &>>"$LOGFILE"; then
        echo -e "${GREEN}SSH server is enabled${NC}"
        echo -e "$(date) - User: $(whoami) - SSH server is enabled" >> "$LOGFILE"
        check_ssh_status
    else
        echo -e "${YELLOW}Warning${NC}: SSH server is not enabled."
        echo -e "$(date) - User: $(whoami) - Warning: SSH server is not enabled." >> "$LOGFILE"
        echo -e "${YELLOW}Enabling SSH server...${NC}"
        sudo systemctl enable sshd &>>"$LOGFILE"
        check_success
        check_ssh_status
    fi
}

# Function to check if SSH server is running
check_ssh_status() {
    echo -e " ${LIGHTBLUE}
 -------------------
| SSH server status |
 ------------------- ${NC}"
    if systemctl is-active --quiet sshd &>>"$LOGFILE"; then
        echo -e "${GREEN}SSH server is running${NC}"
        echo -e "$(date) - User: $(whoami) - SSH server is running" >> "$LOGFILE"
    else
        echo -e "${YELLOW}Warning${NC}: SSH server is not running."
        echo -e "$(date) - User: $(whoami) - Warning: SSH server is not running." >> "$LOGFILE"
        echo -e "${YELLOW}Starting SSH server...${NC}"
        sudo systemctl start sshd &>>"$LOGFILE"
        check_success
    fi
}

# Function to check if a command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success${NC}"
        echo -e "$(date) - User: $(whoami) - Success" >> "$LOGFILE"
    else
        echo -e "${RED}Error${NC}. Check ${LOGFILE} for more details."
        echo -e "$(date) - User: $(whoami) - Error. Check ${LOGFILE} for more details." >> "$LOGFILE"
    fi
}

# Main function
main() {
    check_ssh_installed
}

# Execute main function
main