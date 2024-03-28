#!/bin/bash

# Receive server address
read -p "Enter server address: " SERVER_ADDRESS

# Define the maximum number of attempts
MAX_ATTEMPTS=3

# Initialize the attempt counter
attempt=1

# Try to access the server
while [ $attempt -le $MAX_ATTEMPTS ]
do
    # Receive username and password
    read -p "Enter username: " USERNAME
    read -sp "Enter password: " PASSWORD
    echo

    echo "Attempt $attempt: Trying to access the server..."

    # Try to access the server
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$USERNAME"@"$SERVER_ADDRESS"

    # Check the exit status of the ssh command
    if [ $? -eq 0 ]
    then
        echo "Access granted."
        exit 0
    else
        echo "Access denied. Please enter the correct credentials."
        echo "$(date): Attempt $attempt failed for user $USERNAME trying to access $SERVER_ADDRESS" >> ssh_attempts.log
    fi

    # Increment the attempt counter
    ((attempt++))
done

echo "Maximum number of attempts reached. Please try again later."
echo "WRONG"
read -p "Enter server name: " SERVER_NAME
echo "Copying ssh_attempts.log using rsync to the server..."
rsync ssh_attempts.log "$SERVER_NAME@$SERVER_ADDRESS:$RSYNC_DESTINATION"
sleep 60s && gnome-session-quit --no-prompt
exit 1
