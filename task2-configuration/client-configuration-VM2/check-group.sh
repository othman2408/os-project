#!/bin/bash

# Define the group name
group_name="clients"

# Function to check if the user is part of the specified group
is_user_in_group() {
    groups "$USER" | grep -q "\b$group_name\b"
}

# Check if the group exists, and if not, create it
if ! getent group "$group_name" >/dev/null; then
    echo "The group '$group_name' does not exist. Creating it..."
    sudo groupadd "$group_name"
fi

# Check if the user is already in the group
if is_user_in_group; then
    echo "You are already a member of the '$group_name' group. Proceeding with script execution."
    # Add your script execution commands here
else
    # Prompt the user to obtain superuser privileges to add them to the group
    echo "You are not a member of the '$group_name' group."
    echo "This script requires superuser privileges to add you to the group."

    # Prompt for sudo password and verify it
    read -s -p "Please enter your password for sudo: " sudo_password
    echo
    if sudo -lS &>/dev/null <<< "$sudo_password"; then
        # Add the user to the group
        sudo usermod -aG "$group_name" "$USER"
        echo "You have been added to the '$group_name' group. Proceeding with script execution."
        # Add your script execution commands here
    else
        echo "Incorrect password or insufficient sudo permissions. Exiting."
        exit 1
    fi
fi

# Add your script execution commands here, if needed

