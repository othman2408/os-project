#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Function to check if a command succeeded
check_success() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Success${NC}"
  else
    echo -e "${RED}Error${NC}"
  fi
}

# Create a welcome page
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

# Implement user authentication
echo -e " ${LIGHTBLUE}
 ----------------------------------
| Implementing user authentication |
 ---------------------------------- ${NC}"
echo -n "Enter username: "
read username
echo -n "Enter password: "
read -s password
echo
password_hash=$(openssl passwd -apr1 $password)
sudo sh -c "echo '$username:$password_hash' >> /etc/nginx/.htpasswd"
if ! sudo grep -q 'auth_basic "Restricted";' /etc/nginx/sites-available/default; then
  sudo sed -i 's|location / {|location / {\n    auth_basic "Restricted";\n    auth_basic_user_file /etc/nginx/.htpasswd;|' /etc/nginx/sites-available/default
fi
sudo nginx -t && sudo systemctl reload nginx
check_success

# Define new log format and use it
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

# Print Nginx server status
echo -e " ${LIGHTBLUE}
 ---------------------
| Nginx server status |
 --------------------- ${NC}"
NGINX_STATUS=$(systemctl status nginx | awk '/Active:/ {print $2}')
if [ "$NGINX_STATUS" = "active" ]; then
  echo -e "${GREEN}Nginx server is active${NC}"
  echo
  echo -e "You can access the page at ${ORANGE}http://$(hostname -I | awk '{print $1}')${NC}"
else
  echo -e "${RED}Nginx server is not active${NC}"
fi


# # Nginx access log
# echo -e " ${LIGHTBLUE}
#  ------------------
# | Nginx access log |
#  ------------------ ${NC}"
# sudo tail /var/log/nginx/access.log | awk '{
#     split($4,a,"/");
#     split(a[3],b,":");
#     print "User \047"$3"\047 from IP "$1" made a request on "b[1]"/"a[2]"/"a[1]" at "b[2]":"b[3]":"b[4];
#     print "Request: "$6" "$7" "$8;
#     print "Response status: "$9;
#     print "Response size: "$10" bytes";
#     print "";
# }'

# End of webserver-init.sh