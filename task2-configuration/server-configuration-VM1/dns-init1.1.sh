#!/bin/bash
# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color


# Function to configure Quad9 DNS
configure_quad9_dns() {
    # Find active connection name
    connection_name=$(nmcli -g NAME con show --active)

    if [ -z "$connection_name" ]; then
        echo "Error: No active connection found."
        exit 1
    fi

    # Set DNS servers for IPv4 and IPv6
    nmcli con mod "$connection_name" ipv4.dns "9.9.9.9"
    nmcli con mod "$connection_name" ipv6.dns "2620:fe::fe"

    # Disable automatic DNS
    nmcli con mod "$connection_name" ipv4.ignore-auto-dns yes
    nmcli con mod "$connection_name" ipv6.ignore-auto-dns yes

    # Apply changes
    nmcli con up "$connection_name"

    echo "Quad9 DNS configured successfully for connection: $connection_name"
    
    echo "Your system DNS now: "
    nmcli dev show | grep DNS
    echo
    
}

# Function to change DNS in /etc/resolv.conf
change_resolv_conf() {
    # Define your DNS server
    dns_server="9.9.9.9"

    # Check if the DNS server is already set in /etc/resolv.conf
    if grep -qFx "nameserver $dns_server" /etc/resolv.conf; then
        echo -e "${YELLOW}DNS server $dns_server is already set in /etc/resolv.conf.${NC}"
        return
    fi

    # Backup the original resolv.conf
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup

    # Comment out the existing nameserver line and add a new nameserver line
    sudo sed -i '/^nameserver/s/^/#/' /etc/resolv.conf  # Comment out existing nameserver lines
    sudo sed -i '$a\nameserver '"$dns_server" /etc/resolv.conf  # Add a new nameserver line at the end of the file

    # Restart systemd-resolved to apply the changes
    sudo systemctl restart systemd-resolved

    echo -e "${GREEN}DNS server has been changed to $dns_server in /etc/resolv.conf.${NC}"
}


# Main script
echo "Configuring Quad9 DNS..."

# Check if NetworkManager is installed
if ! command -v nmcli &> /dev/null; then
    echo -e "${RED}Error: NetworkManager (nmcli) is not installed. Please install it to continue.${NC}"
    exit 1
fi

# Run configuration function
configure_quad9_dns

# Change DNS in /etc/resolv.conf
change_resolv_conf

echo -e "You can use the ${GREEN}'nmcli dev show | grep DNS'${NC} command to verify the DNS settings."
echo -e "Please visit ${GREEN}https://on.quad9.net${NC} to check if Quad9 DNS is set up and working correctly."
echo -e "You can use ${GREEN}'sudo apt install dnsutils -y'${NC} followed by ${GREEN}'dig google.com'${NC} to test the DNS resolution."


# End of script