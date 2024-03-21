#!/bin/bash

# Group name for authorized users
authorized_group="clients"

# Function to check group membership
is_authorized_user() {
  if groups | grep -q "$authorized_group"; then
    return 0  # User is in the group
  else
    return 1  # User is not in the group
  fi
}

# Check if the authorized group exists
if ! getent group "$authorized_group" >/dev/null 2>&1; then
  echo "The '$authorized_group' group does not exist. Creating it with sudo..."
  sudo groupadd "$authorized_group"
fi

# Check if the user is in the authorized group
if ! is_authorized_user; then
  # Not in the group, prompt for superuser privileges
  echo "You are not a member of the '$authorized_group' group."
  echo "This script requires superuser privileges to add you."
  echo "Please enter the password for a user with sudo permissions (not root):"

  # Read password securely using read -s
  read -s -p "Password: " sudo_password
  echo

  # Verify sudo password using sudo -S (avoid storing password in script)
  if ! sudo -S echo " " <<< "$sudo_password"; then
    echo "Incorrect password. Exiting..."
    exit 1
  fi

  # Add user to the authorized group with sudo
  sudo usermod -a -G "$authorized_group" "$(whoami)"
  echo "You have been added to the '$authorized_group' group. The script will now proceed."
fi

# Place your main script functionalities here (assuming user is now authorized)

# Example: Display a message only accessible to authorized users
echo "Welcome, authorized user!"

# ... place your other script functionalities here ...


