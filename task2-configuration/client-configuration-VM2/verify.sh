#!/bin/bash

# Colors 
GREEN='\033[0;32m'
LIGHTBLUE='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# # Creates admins group
createGroup() {
    if ! getent group "admins" > "/dev/null" 
    then    
        sudo groupadd "admins"
    else
        echo -e "${YELLOW}Skipping...${NC} group already exists"
    fi
}

# Adds the admins group to sudoers file
addGroupToSudoers() {
    if ! grep "^%admins" "/etc/sudoers" > "/dev/null" 2>&1 
    then
        echo -e "Adding ${LIGHTBLUE}admins${NC} to sudoers file..."
        echo "%admins    ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo > /dev/null
        echo -e "Group ${LIGHTBLUE}admins${NC} added ${GREEN}successfully${NC}"
    else
        echo -e "${YELLOW}Skipping...${NC} group already in sudoers file"
    fi
}

# Add user to admins group
addUserToGroup() {
    # Check if user is already in the "admins" group
    if ! groups "$1" | grep -q "admins"; then
        sudo usermod -aG "admins" "$1"
        echo -e "${LIGHTBLUE}$1${NC} added to ${LIGHTBLUE}admins${NC} ${GREEN}successfully${NC}"
    else
        echo -e "${YELLOW}Skipping...${NC} user ${LIGHTBLUE}$1${NC} already in ${LIGHTBLUE}admins${NC} group"
    fi
    echo -e "Running ${LIGHTBLUE}./main.sh${NC} under ${LIGHTBLUE}$user${NC}"
    echo -e "Executing ${LIGHTBLUE}./main.sh${NC}"
    sudo -u "$1" ./main.sh
}

main() {
    # Wait till user enters a valid username
    while [ true ]
    do
        echo -n "Name of admin user: "
        read user
        # User does not exist
        if ! id "$user" > "/dev/null" 2>&1
        then
            sudo useradd "$user" 
            sudo passwd "$user" 
            echo -e "User ${LIGHTBLUE}"$user"${NC} created ${GREEN}successfully${NC} on ${LIGHTBLUE}$(date +%Y-%m-%d--%I-%M-%S)${NC}"
            break
        # User exists    
        else
            echo -e "${YELLOW}Skipping:${NC} ${LIGHTBLUE}$user${NC} already exists..."
            break
        fi
    done
    echo -e "Attempt to run ${LIGHTBLUE}./main.sh${NC} under ${LIGHTBLUE}$user${NC}"
    echo -e "Executing ${LIGHTBLUE}./main.sh${NC}"
    # Give execute permission to main.sh
    chmod +x main.sh
    sudo -u $user ./main.sh $user
    sleep 1
    createGroup
    addGroupToSudoers
    addUserToGroup $user
}

main
