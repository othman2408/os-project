#!/bin/bash

traceroute $1
echo "---------------------------------------------"
echo -n "Reboot recommended for troubleshooting, would you like to proceed (y/n)? "
read choice

if [ ${choice} = "y" ]
then
    echo "Rebooting intitiated..."
    sleep 1
    sudo reboot
else    
    echo "Reboot aborted"
fi
