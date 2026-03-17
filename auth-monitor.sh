#!/bin/bash

# Configuration
EMAIL="YOUR-EMAIL@gmail.com" # just change this to your email and the shell will work fine
LOG_FILE="/var/log/auth.log"
THRESHOLD=3
STATE_FILE="/dev/shm/failed_login_notified"

# 1. Set the Window to 24 Hours
# This matches the timestamp format in auth.log (e.g., Mar 17 03:30)
WINDOW_START=$(date -d '24 hours ago' "+%b %_d %H:%M")

# 2. Count failures specifically within that 24-hour window
RECENT_FAILURES=$(awk -v since="$WINDOW_START" '$0 >= since' "$LOG_FILE" | \
    grep "gdm-password]: pam_unix(gdm-password:auth): authentication failure" | wc -l)

# 3. Decision Logic
if [ "$RECENT_FAILURES" -ge "$THRESHOLD" ]; then
    
    # Only send an email if the count has increased since the last check
    if [ ! -f "$STATE_FILE" ] || [ "$RECENT_FAILURES" -gt "$(cat $STATE_FILE)" ]; then
        
        # Gather Network Intelligence
        PUBLIC_IP=$(curl -s --max-time 5 https://ifconfig.me || echo "Timeout/No Internet")
        LOCAL_IP=$(hostname -I | awk '{print $1}')
        NEARBY_WIFI=$(nmcli -t -f SSID dev wifi | head -n 5 | tr '\n' ', ')

        REPORT=$(cat <<EOF
Subject: SECURITY ALERT: $RECENT_FAILURES Failed Logins on $(hostname)
To: $EMAIL

Security Alert: Multiple failed login attempts detected in the last 24 hours.

--- NETWORK CONTEXT ---
Public IP:    $PUBLIC_IP
Local IP:     $LOCAL_IP
Nearby WiFi:  $NEARBY_WIFI

--- CURRENTLY LOGGED IN ---
$(who)

--- SYSTEM TIME ---
Report Generated: $(date)
EOF
)
        # Send the email via msmtp
        echo "$REPORT" | msmtp -t "$EMAIL"
        
        # Save the current count to prevent duplicate alerts
        echo "$RECENT_FAILURES" > "$STATE_FILE"
    fi
else
    # Reset the state if failures drop below threshold (clean login)
    rm -f "$STATE_FILE"
fi
