#!/bin/bash

# Receive server address
read -p "Enter server address: " SERVER_ADDRESS
read -p "Enter server name to make the connection: " SERVER_NAME

# Define the maximum number of attempts
MAX_ATTEMPTS=3

# Initialize a variable to track if access is granted
access_granted=false

# Loop for three attempts
for (( attempt=1; attempt<=$MAX_ATTEMPTS; attempt++ ))
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
        access_granted=true
        break
    else
        echo "Access denied. Please enter the correct credentials."
        echo "$(date): Attempt $attempt failed for user $USERNAME trying to access $SERVER_ADDRESS" >> ssh_attempts.log
    fi
done

# Check if access is not granted after all attempts
if ! $access_granted
then
    echo "Wrong"
    
    # Attempt to copy ssh_attempts.log using rsync to the server
    echo "Copying ssh_attempts.log using rsync to the server..."
        rsync ssh_attempts.log "$SERVER_NAME@$SERVER_ADDRESS:$RSYNC_DESTINATION"
        sleep 5s && gnome-session-quit --no-prompt

    exit 1
fi
