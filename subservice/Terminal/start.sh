#!/bin/bash
# ArozOS Terminal Subservice
# Launches ttyd as a reverse-proxied subservice
#
# Icon: synthwave_option_6.png from https://github.com/dhanishgajjar/terminal-icons
#       by Dhanish Gajjar (MIT License)

PORT=""

# Parse ArozOS subservice arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -port)
            # ArozOS passes port as ":XXXX" or "XXXX" depending on .intport flag
            PORT="${2#:}"
            shift 2
            ;;
        -rpt)
            # Reverse proxy target — not needed for ttyd
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$PORT" ]; then
    echo "ERROR: No port specified"
    exit 1
fi

echo "Starting Terminal on port $PORT"
exec ttyd -W -t disableReconnect=true -p "$PORT" /bin/bash
