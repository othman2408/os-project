#!/bin/bash

# Colors
LIGHTBLUE='\033[0;36m'
NC='\033[0m' # No Color

echo "--------------------------------------------------------------------------------"
echo -e "${LIGHTBLUE}STEP 1: Check User Group Membership${NC}"
./check-group.sh
echo "--------------------------------------------------------------------------------"
echo -e "${LIGHTBLUE}STEP 2: Log Invalid Attempts${NC}"
./handle-attempts.sh
echo "--------------------------------------------------------------------------------"
echo -e "${LIGHTBLUE}STEP 3: Handle Excessive Invalid Attempts${NC}"
./invalid-attempts.sh
