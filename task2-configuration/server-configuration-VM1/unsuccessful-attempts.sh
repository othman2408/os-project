#!/bin/bash

echo -e " ${LIGHTBLUE}
---------------------------------------
| Unsuccessful Attempts Script Tracker |
--------------------------------------- ${NC}"

# NGINX access log
ACCESS_LOG="/var/log/nginx/access.log"

# File to write 'GET 401' lines to
ERROR_LOG="unsuccessful_attempts.log"

# Continuously read from the access log, filter for status code 401, and write to error log
tail -f "$ACCESS_LOG" | grep --line-buffered ' 401 ' > "$ERROR_LOG" &

# Get the PID of the background process
PID=$!

# Run indefinitely
while true; do
    # Delete the error log if it's more than one week old
    find "$(dirname "$ERROR_LOG")" -name "$(basename "$ERROR_LOG")" -mtime +7 -exec rm {} +

    # Sleep for 1 day before running again
    sleep 86400
done

# Kill the background process when the script exits
trap "kill $PID" EXIT
