#!/bin/bash

# Threshold for CPU usage
CPU_THRESHOLD=80
# Service name for the Laravel backend
SERVICE_NAME="laravel-backend"
# Interval to check CPU usage (in seconds)
CHECK_INTERVAL=10

while true; do
    # Get the CPU usage as an integer
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | \
                sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \
                awk '{print 100 - $1}')

    # Compare CPU usage with the threshold
    if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
        echo "CPU usage is above $CPU_THRESHOLD%. Restarting $SERVICE_NAME."

        # Restart the Laravel backend service
        sudo systemctl restart $SERVICE_NAME

        # Log the restart action
        echo "$(date): Restarted $SERVICE_NAME due to high CPU usage ($CPU_USAGE%)" >> /var/log/laravel_restart.log
    else
        echo "CPU usage is at $CPU_USAGE%. No action needed."
    fi

    # Wait for the specified interval before checking again
    sleep $CHECK_INTERVAL
done
