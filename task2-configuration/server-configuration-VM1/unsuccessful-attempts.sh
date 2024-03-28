#!/bin/bash

# SSH log file
SSH_LOG="/var/log/auth.log"

# unsuccessful attempts
ERROR_LOG="unsuccessful_attempts.log"

# monitor SSH logs for unsuccessful attempts
monitor_ssh_logs() {
    # Keep read from SSH log and filter for unsuccessful attempts and redirected to the log file
    tail -n0 -F "$SSH_LOG" | grep --line-buffered 'authentication failure' > "$ERROR_LOG" &

    # keep running
    while true; do
        # delete the error log if it's more than one week
        find "$(dirname "$ERROR_LOG")" -name "$(basename "$ERROR_LOG")" -mtime +7 -delete

        # Sleep for 1 day before run again
        sleep 86400
    done
}

# Main function
main() {
    monitor_ssh_logs
}


main
