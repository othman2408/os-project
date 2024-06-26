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
LIGHTBLUE='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Define log file
LOGFILE="$(dirname "$0")/server-init.log"

# Define array to store users
USERS=()

# Function to display success or error message
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success${NC}"
        echo -e "$(date) - User: $(whoami) - Success" >>"$LOGFILE"
    else
        echo -e "${RED}Error${NC}. Check ${LOGFILE} for more details."
        echo -e "$(date) - User: $(whoami) - Error. Check ${LOGFILE} for more details." >>"$LOGFILE"
    fi
}

# Function to create user accounts
create_user_accounts() {
    echo -e " ${LIGHTBLUE}
 ------------------------
| Creating User Accounts |
 ------------------------ ${NC}"

    echo -n "How many users do you want to create? "
    read NUM_USERS

    while true; do
        if [[ ! "$NUM_USERS" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Error${NC}: Please enter a valid number."
            echo -n "How many users do you want to create? "
            read NUM_USERS
        else
            break
        fi
    done

    for ((i = 1; i <= NUM_USERS; i++)); do
        while true; do
            echo -n "Enter username for user $i: "
            read USER
            if id "$USER" &>/dev/null; then
                echo -e "${YELLOW}Warning${NC}: User $USER already exists. Please enter a different username."
            else
                break  # Break the loop when a valid username is provided
            fi
        done
        
        USERS+=("$USER")  
        echo "Creating user $USER... "
        # Create user with home directory
        sudo useradd -m "$USER" >>"$LOGFILE" 2>&1
        # Set password for the user
        echo -n "Enter password for user $USER: "
        read -s PASSWORD
        echo
        echo "$USER:$PASSWORD" | sudo chpasswd

        # Add the created user to the Nginx password file (append without -c option)
        # Check if the password file exists
        if [ ! -f /etc/nginx/.htpasswd ]; then
            # If the file does not exist, create it
            htpasswd -c -b /etc/nginx/.htpasswd "$USER" "$PASSWORD"
        else
            # If the file exists, append the user
            htpasswd -b /etc/nginx/.htpasswd "$USER" "$PASSWORD"
        fi
        sudo nginx -t && sudo systemctl reload nginx
        check_success
    done

    for USER in "${USERS[@]}"; do
        echo "User $USER created successfully."
    done
}

# Function to update package lists
update_package_lists() {
    echo -e "${LIGHTBLUE}
 ------------------------
| Updating Package Lists |
 ------------------------ ${NC}"
    echo -n "Updating package lists..."
    echo
    sudo apt update >>"$LOGFILE" 2>&1
    check_success
}

# Function to install and configure NGINX
install_configure_nginx() {
    echo -e " ${LIGHTBLUE}
 --------------------------------------
| NGINX Installation and Configuration |
 -------------------------------------- ${NC}"
    if ! dpkg -s nginx >/dev/null 2>&1; then
        echo -n "Installing NGINX... "
        sudo apt install -y nginx >>"$LOGFILE" 2>&1
        check_success
    else
        echo -e "${YELLOW}Warning${NC}: NGINX is already installed. "
        echo -e "$(date) - User: $(whoami) - Warning: NGINX is already installed. " >>"$LOGFILE"
    fi

    echo -n "Starting NGINX... "
    sudo systemctl start nginx >>"$LOGFILE" 2>&1
    check_success

    echo -n "Enabling NGINX to start on boot... "
    sudo systemctl enable nginx >>"$LOGFILE" 2>&1
    check_success

    echo -n "Installing apache2-utils..."
    sudo apt-get install -y apache2-utils >>"$LOGFILE" 2>&1
    check_success

}

# Function to display NGINX server information
nginx_server_information() {
    echo -e " ${LIGHTBLUE}
 --------------------------
| NGINX Server Information |
 -------------------------- ${NC}"
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}NGINX is running${NC}"
        echo "Server Name: $(logname)"
        echo "Server IPv4: $(hostname -I | awk '{print $1}')"
        echo -e "$(date) - User: $(whoami) - NGINX is running" >>"$LOGFILE"
        echo "Server Name: $(hostname)" >>"$LOGFILE"
        echo "Server IPv4: $(hostname -I | awk '{print $1}')" >>"$LOGFILE"
    fi
}

# Function to install and configure SSHD
install_configure_sshd() {
    echo -e " ${LIGHTBLUE}
 -------------------------------------
| SSHD Installation and Configuration |
 ------------------------------------- ${NC}"
    if ! dpkg -s openssh-server >/dev/null 2>&1; then
        echo -n "Installing SSHD... "
        sudo apt install -y openssh-server >>"$LOGFILE" 2>&1
        check_success
    else
        echo -e "${YELLOW}Warning${NC}: SSHD is already installed. "
        echo -e "$(date) - User: $(whoami) - Warning: SSHD is already installed. " >>"$LOGFILE"
    fi

    # Enable SSHD if not already enabled
    if ! systemctl is-enabled --quiet ssh; then
        echo -n "Enabling SSHD to start on boot... "
        sudo systemctl enable ssh >>"$LOGFILE" 2>&1
        check_success
    else
        echo -e "${YELLOW}Warning${NC}: SSHD is already enabled. "
        echo -e "$(date) - User: $(whoami) - Warning: SSHD is already enabled. " >>"$LOGFILE"
    fi

    # Start SSHD if not already started
    if ! systemctl is-active --quiet ssh; then
        echo -n "Starting SSHD... "
        sudo systemctl start ssh >>"$LOGFILE" 2>&1
        check_success
    else
        echo -e "${YELLOW}Warning${NC}: SSHD is already running."
        echo -e "$(date) - User: $(whoami) - Warning: SSHD is already running." >>"$LOGFILE"
    fi
}


# Function to configure SSHD for SFTP and SSH access
configure_sshd_sftp() {
    echo -e " ${LIGHTBLUE}
 ------------------------------
| SSHD Configuration for SFTP |
|      and SSH Access         |
 ------------------------------ ${NC}"

    # Check if the group sftp_users already exists
    if ! getent group sftp_users >/dev/null; then
        # If the group doesn't exist, create it
        sudo groupadd sftp_users
    fi

    # Add users to the sftp_users group
    for USER in "${USERS[@]}"; do
        sudo usermod -aG sftp_users "$USER"
    done

    # Check if the SSH configuration block for sftp_users already exists in sshd_config
    if ! grep -q "Match Group sftp_users" /etc/ssh/sshd_config; then
        # Add SSH configuration for the sftp_users group
        {
            echo "Match Group sftp_users"
            echo "    AllowTCPForwarding yes"
            echo "    X11Forwarding yes"
            echo "    ForceCommand none"
        } | sudo tee -a /etc/ssh/sshd_config >>"$LOGFILE" 2>&1
    else
        echo -e "${YELLOW}Warning${NC}: SSH configuration for sftp_users group already exists."
    fi

    # Check if the group ssh_users already exists
    if ! getent group ssh_users >/dev/null; then
        # If the group doesn't exist, create it
        sudo groupadd ssh_users
    fi

    # Add users to the ssh_users group
    for USER in "${USERS[@]}"; do
        sudo usermod -aG ssh_users "$USER"
    done

    # Check if the SSH configuration block for ssh_users already exists in sshd_config
    if ! grep -q "Match Group ssh_users" /etc/ssh/sshd_config; then
        # Add SSH configuration for the ssh_users group
        {
            echo "Match Group ssh_users"
            echo "    AllowTCPForwarding yes"
            echo "    X11Forwarding yes"
            echo "    ForceCommand none"
        } | sudo tee -a /etc/ssh/sshd_config >>"$LOGFILE" 2>&1
    else
        echo -e "${YELLOW}Warning${NC}: SSH configuration for ssh_users group already exists."
    fi

    # Restart SSHD
    restart_sshd
}

# Function to restart SSHD
restart_sshd() {
    echo -n "Restarting SSHD... "
    sudo systemctl restart ssh >>"$LOGFILE" 2>&1
    check_success
}

# Function to display SSHD server information
sshd_server_information() {
    echo -e " ${LIGHTBLUE}
 -------------------------
| SSHD Server Information |
 ------------------------- ${NC}"
    if systemctl is-active --quiet ssh; then
        echo -e "${GREEN}SSHD is running${NC}"
        echo "Server Name: $(logname)"
        echo "Server IPv4: $(hostname -I | awk '{print $1}')"
        echo -e "$(date) - User: $(whoami) - SSHD is running" >>"$LOGFILE"
        echo "Server Name: $(hostname)" >>"$LOGFILE"
        echo "Server IPv4: $(hostname -I | awk '{print $1}')" >>"$LOGFILE"
    fi
}

# Main function
main() {
    install_configure_nginx
    install_configure_sshd
    create_user_accounts
    update_package_lists
    nginx_server_information
    install_configure_sshd
    configure_sshd_sftp
    restart_sshd
    sshd_server_information
}

# Execute main function
main
