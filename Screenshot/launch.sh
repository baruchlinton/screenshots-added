#!/bin/sh


SCRIPT_NAME=screenshot.sh
LOG_FILE=/mnt/SDCARD/screenshot.log
SCRIPT_PATH=/mnt/SDCARD/Apps/Screenshot/$SCRIPT_NAME

if pgrep -f $SCRIPT_PATH > /dev/null; then
    echo "$(date): $SCRIPT_NAME is already running. Stopping the process." >> $LOG_FILE
    pkill -f $SCRIPT_PATH
    exit 0 
else
    echo "$(date): $SCRIPT_NAME not running, starting now..." >> $LOG_FILE
    /bin/sh $SCRIPT_PATH &
fi
