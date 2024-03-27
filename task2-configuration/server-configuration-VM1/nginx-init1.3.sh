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
  html_file_path=$(ls $(dirname "$0")/html/index* | head -n 1)
  if [ -f "$html_file_path" ]; then
    sudo cp "$html_file_path" /var/www/html/index.nginx-debian.html
    check_success
  else
    echo -e "${RED}Error: No file starting with 'index' found in the script directory${NC}"
  fi
}

# Function for user authentication
enable_auth() {
	echo -e " ${LIGHTBLUE}
 -----------------------------------
| User Authentication Configuration |
 ----------------------------------- ${NC}"
    # Check if authentication configuration exists
    if ! sudo grep -q 'auth_basic "Restricted";' /etc/nginx/sites-available/default &&
       ! sudo grep -q 'auth_basic_user_file /etc/nginx/.htpasswd;' /etc/nginx/sites-available/default; then
        # Append authentication configuration within location block
        {
            echo '            auth_basic "Restricted";'
            echo '            auth_basic_user_file /etc/nginx/.htpasswd;'
        } | sudo tee -a /etc/nginx/sites-available/default >/dev/null
        # Test and reload NGINX
        sudo nginx -t && sudo systemctl reload nginx
        check_success
    else
        echo -e "${YELLOW}Warning:${NC} NGINX authentication configuration already exists."
    fi
}

# Function to configure logging
configure_logging() {
    	echo -e " ${LIGHTBLUE}
 -------------------------
| Looggin Access Requests |
 ------------------------- ${NC}"
    # Current script directory
    CURR_DIR=$(dirname "$0")

    NGINX_ACCESS_LOG="/var/log/nginx/access.log"
    RECORD_LOG="$CURR_DIR/access.log"

    # Check if the access log file exists
    if [ ! -f "$NGINX_ACCESS_LOG" ]; then
        echo "There is no access requests yet!...: $NGINX_ACCESS_LOG"
        return 1
    fi

    echo -e "${YELLOW}Warning:${NC} Access requests are being recorded in: $RECORD_LOG"
    # Continuously append content of NGINX_ACCESS_LOG to RECORD_LOG
    tail -n0 -F "$NGINX_ACCESS_LOG" >> "$RECORD_LOG" &
}


# Function to display Nginx server status
nginx_status() {
  echo -e " ${LIGHTBLUE}
 ---------------------
| Nginx server status |
 --------------------- ${NC}"

  if systemctl is-enabled --quiet nginx && systemctl is-active --quiet nginx; then
    echo -e "${GREEN}Nginx server is active${NC}"
    echo
    echo -e "You can access the page at ${ORANGE}http://$(hostname -I | awk '{print $1}')${NC}"
    # print server details
    echo -e "Find Nginx server files in: ${ORANGE}/etc/nginx${NC}"
  else
    echo -e "${RED}Nginx server is not active${NC}"
    echo "Attempting to start Nginx server..."
    sudo systemctl start nginx
    echo "Nginx server started."
  fi
}

# Function to start unsuccessful attempts script
start_unsuccessful_attempts() {
  echo -e " ${LIGHTBLUE}
 ----------------------------------------
| Starting Unsuccessful Attempts Tracker |
 ---------------------------------------- ${NC}"

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
  start_unsuccessful_attempts
}

# Execute main function
main