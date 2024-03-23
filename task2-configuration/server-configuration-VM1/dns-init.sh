#!/bin/bash

# Function to configure Quad9 DNS
configure_quad9_dns() {
    # Find active connection name
    connection_name=$(nmcli -g NAME con show --active)

    if [ -z "$connection_name" ]; then
        echo "Error: No active connection found."
        exit 1
    fi

    # Set DNS servers for IPv4 and 
    # ,149.112.112.112
    # ,2620:fe::9
    nmcli con mod "$connection_name" ipv4.dns "9.9.9.9"
    nmcli con mod "$connection_name" ipv6.dns "2620:fe::fe"

    # Disable automatic DNS
    nmcli con mod "$connection_name" ipv4.ignore-auto-dns yes
    nmcli con mod "$connection_name" ipv6.ignore-auto-dns yes

    # Apply changes
    nmcli con up "$connection_name"

    echo "Quad9 DNS configured successfully for connection: $connection_name"
    
    echo "Your systme DNS now: "
    nmcli dev show | grep DNS
    echo
    
    echo "Please visit https://on.quad9.net to check if Quad9 DNS is set up and working correctly."
}

# Main script
echo "Configuring Quad9 DNS..."

# Check if NetworkManager is installed
if ! command -v nmcli &> /dev/null; then
    echo "Error: NetworkManager (nmcli) is not installed. Please install it to continue."
    exit 1
fi

# Run configuration function
configure_quad9_dns

