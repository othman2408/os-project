#!/bin/bash

# Colors 
GREEN='\033[0;32m'
LIGHTBLUE='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ping status and detailed output
LOGFILE="network.log"

# This function pings the specified ip address
pingIp() {
    echo -e "Now will ping IP address: ${LIGHTBLUE}$1${NC}:"
    if ping -c 3 -W 3 -q $1 >> ${LOGFILE}
    then
        echo -e "Connectivity with target IP ${LIGHTBLUE}$1${NC} is ${GREEN}OK${NC}\n$(date +%Y-%m-%d--%I-%M-%S)"
    else
        echo -e "${RED}Connection failed...${NC}"
        echo "Processing troubleshooting to resolve connectivity issue..."
        if [ ! -x ${LOGFILE} ]
        then
            chmod u+x troubleshoot.sh
        fi
        ./troubleshoot.sh $1
    fi
}

pingIp $1 
pingIp $2

