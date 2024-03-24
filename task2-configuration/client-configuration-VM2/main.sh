#!/bin/bash

# Colors
LIGHTBLUE='\033[0;36m'
NC='\033[0m' # No Color
user=$1
echo "--------------------------------------------------------------------------------"
echo -e "${LIGHTBLUE}STEP 1: Check User Group Membership${NC}"
./check-group.sh $user
echo "--------------------------------------------------------------------------------"
echo -e "${LIGHTBLUE}STEP 2 & 3: Log Invalid Attempts and send a file to server via rsync${NC}"
./invalid-attempts.sh
