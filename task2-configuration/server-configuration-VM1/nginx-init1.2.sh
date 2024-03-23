#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Function to display success or error message
check_success() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Success${NC}"
  else
    echo -e "${RED}Error${NC}"
  fi
}

# Function to create welcome page
create_welcome_page() {
  echo -e " ${LIGHTBLUE}
 -----------------------
| Creating welcome page |
 ----------------------- ${NC}"
  index_file_path=$(ls $(dirname "$0")/html/index* | head -n 1)
  if [ -f "$index_file_path" ]; then
    sudo cp "$index_file_path" /var/www/html/index.nginx-debian.html
    check_success
  else
    echo -e "${RED}Error: No file starting with 'index' found in the script directory${NC}"
  fi
}

# # Function for user authentication
enable_auth() {
	echo -e " ${LIGHTBLUE}
 --------------------------------
| User Authentication Configuration |
 -------------------------------- ${NC}"
	# Check if authentication configuration exists
	if ! sudo grep -q 'auth_basic "Restricted";' /etc/nginx/sites-available/default; then
		echo "Configuring NGINX for authentication..."
		sudo sed -i '/location \/ {/a \ \ \ \ auth_basic "Restricted";' /etc/nginx/sites-available/default
		sudo sed -i '/location \/ {/a \ \ \ \ auth_basic_user_file /etc/nginx/.htpasswd;' /etc/nginx/sites-available/default
		sudo nginx -t && sudo systemctl reload nginx
		check_success
	else
		echo -e "${YELLOW}Warning:${NC} NGINX authentication configuration already exists."
	fi
}

# Function to configure logging
configure_logging() {
  echo -e " ${LIGHTBLUE}
 ---------------------
| Configuring logging |
 --------------------- ${NC}"
  if ! sudo grep -q 'log_format myformat' /etc/nginx/nginx.conf; then
    sudo sed -i '/http {/a \ \ log_format myformat '\''$remote_addr - $remote_user [$time_local] "$request"'\'';' /etc/nginx/nginx.conf
  fi
  sudo sed -i 's|access.log;|access.log myformat;|' /etc/nginx/sites-available/default
  sudo nginx -t && sudo systemctl reload nginx
  check_success
}

# Function to display Nginx server status
nginx_status() {
  echo -e " ${LIGHTBLUE}
 ---------------------
| Nginx server status |
 --------------------- ${NC}"
  NGINX_STATUS=$(systemctl status nginx | awk '/Active:/ {print $2}')
  if [ "$NGINX_STATUS" = "active" ]; then
    echo -e "${GREEN}Nginx server is active${NC}"
    echo
    echo -e "You can access the page at ${ORANGE}http://$(hostname -I | awk '{print $1}')${NC}"
    # print servere detials
    echo -e "Find Nginx server files in: ${ORANGE}cd /etc/nginx${NC}"
  else
    echo -e "${RED}Nginx server is not active${NC}"
  fi
}

# Function to display Nginx access log
nginx_access_log() {
  echo -e " ${LIGHTBLUE}
 ------------------
| Nginx access log |
 ------------------ ${NC}"
  echo -e "Access log file: ${ORANGE}/var/log/nginx/access.log${NC}"
  echo -e "Do you want to display the last 10 lines of the access log? (y/n)"
  read -n 1 display_log
  echo
  if [ "$display_log" = "y" ]; then
    # show only important information ip, user, request, status,
    sudo tail -n 10 /var/log/nginx/access.log | awk '{print $1, $3, $4, $5, $6, $7, $9}'
    # sudo tail /var/log/nginx/access.log
  fi
}

# Function to start unsuccessful attempts script
start_unsuccessful_attempts() {
  echo -e " ${LIGHTBLUE}
-----------------------------------------
| Starting Unsuccessful Attempts Tracker |
----------------------------------------- ${NC}"

  # Run the unsuccessful-attempts.sh script in the background
  ./unsuccessful-attempts.sh &
  check_success
}

# Main function
main() {
  create_welcome_page
  enable_auth
  configure_logging
  nginx_status
  nginx_access_log
  start_unsuccessful_attempts
}

# Execute main function
main
