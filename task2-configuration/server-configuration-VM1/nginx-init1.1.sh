#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Function to display success or error message
print_result() {
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
    print_result
  else
    echo -e "${RED}Error: No file starting with 'index' found in the script directory${NC}"
  fi
}

# Function for user creation and authentication
user_auth() {
	echo -e " ${LIGHTBLUE}
 --------------------------------
| User Creation & authentication |
 -------------------------------- ${NC}"
	echo -n "Do you want to create a new user for authentication? (y/n) "
	read -n 1 create_user
	echo

	if [ "$create_user" = "y" ]; then
		# Check if username already exists
		while true; do
			echo -n "Enter username: "
			read username
			if sudo grep -q "^$username:" /etc/nginx/.htpasswd; then
				echo -e "${YELLOW}Warning: User '$username' already exists.${NC}"
			else
				break
			fi
		done
		echo -n "Enter password: "
		read -s password
		echo
		password_hash=$(openssl passwd -apr1 $password)
		sudo sh -c "echo '$username:$password_hash' >> /etc/nginx/.htpasswd"
		if ! sudo grep -q 'auth_basic "Restricted";' /etc/nginx/sites-available/default; then
			sudo sed -i 's|location / {|location / {n    auth_basic "Restricted";n    auth_basic_user_file /etc/nginx/.htpasswd;|' /etc/nginx/sites-available/default
		fi
		sudo nginx -t && sudo systemctl reload nginx
		print_result
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
  print_result
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
    sudo tail /var/log/nginx/access.log
  fi
}

# Main function
main() {
  create_welcome_page
  user_auth
  configure_logging
  nginx_status
  nginx_access_log
}

# Execute main function
main
