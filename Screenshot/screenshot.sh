#!/bin/sh

# Event device for the controller
EVENT_DEVICE="/dev/input/event3"

# Directory to save screenshots
SCREENSHOT_DIR="/mnt/SDCARD/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Log files
LOG_FILE="/mnt/SDCARD/Screenshots_log.log"
BUTTON_LOG_FILE="/mnt/SDCARD/buttonpresses.log"

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
export PATH="$SCRIPT_DIR:$PATH"

# Button combination for taking screenshots
BUTTON1="R2"
BUTTON2="L2"
TIMEOUT=1  # Time window in seconds for pressing both buttons

take_screenshot() {
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  FILENAME="$SCREENSHOT_DIR/screenshot_$TIMESTAMP.png"
  /usr/trimui/bin/fbscreencap "$FILENAME"
  if [ $? -eq 0 ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Screenshot saved to $FILENAME" >> "$LOG_FILE"
    sdl2imgshow \
      -i "/mnt/SDCARD/Apps/MyIP/bg.png" \
      -f "/mnt/SDCARD/Apps/MyIP/font.ttf" \
      -s 45 \
      -c "255,0,0" \
      -t "Screenshot Taken" &

    sleep 0.5
    PID=$(pgrep -f sdl2imgshow)
    if [ -n "$PID" ]; then
      kill "$PID"
    fi
  else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Failed to take screenshot" >> "$LOG_FILE"
  fi
}

# Button mapping table
map_button() {
    case "$1" in
        305) echo "A" ;;
        304) echo "B" ;;
        307) echo "Y" ;;
        308) echo "X" ;;
        310) echo "L" ;;
        311) echo "R" ;;
        314) echo "SELECT" ;;
        315) echo "START" ;;
        316) echo "MENU" ;;
        1)   echo "FN" ;;
        17:-1) echo "UP" ;;
        17:1)  echo "DOWN" ;;
        16:-1) echo "LEFT" ;;
        16:1)  echo "RIGHT" ;;
        2:255) echo "R2" ;;
        5:255) echo "L2" ;;
        *)     echo "" ;;
    esac
}

# Monitor button presses
monitor_buttons() {
  BUTTON1_PRESSED=0
  BUTTON2_PRESSED=0
  BUTTON1_TIME=0
  BUTTON2_TIME=0

  /mnt/SDCARD/System/usr/trimui/scripts/evtest "$EVENT_DEVICE" | while read -r line; do
    # Check if the line contains an EV_KEY, EV_ABS, or EV_SW event
    if echo "$line" | grep -E "EV_KEY|EV_ABS|EV_SW" > /dev/null; then
        # Extract the event type, code, and value from the line
        EVENT_TYPE=$(echo "$line" | awk '{print $6}')
        EVENT_CODE=$(echo "$line" | awk '{print $8}')
        EVENT_VALUE=$(echo "$line" | awk '{print $NF}')
        CURRENT_TIME=$(date +%s)

        # Validate that EVENT_CODE and EVENT_VALUE are numbers before proceeding
        if echo "$EVENT_CODE" | grep -Eq '^[0-9]+$' && echo "$EVENT_VALUE" | grep -Eq '^-?[0-9]+$'; then
            # Check if the key was pressed (value 1) or the relevant ABS/SW event occurred
            if [ "$EVENT_TYPE" = "(EV_KEY)," ] && [ "$EVENT_VALUE" -eq 1 ]; then
                BUTTON=$(map_button "$EVENT_CODE")
            elif [ "$EVENT_TYPE" = "(EV_ABS)," ]; then
                BUTTON=$(map_button "$EVENT_CODE:$EVENT_VALUE")
            elif [ "$EVENT_TYPE" = "(EV_SW)," ]; then
                BUTTON=$(map_button "$EVENT_CODE:$EVENT_VALUE")
            else
                BUTTON=""
            fi

            if [ -n "$BUTTON" ]; then
                # Log the button press
                echo "$(date +"%Y-%m-%d %H:%M:%S") - Button pressed: $BUTTON" >> "$BUTTON_LOG_FILE"

                if [ "$BUTTON" = "$BUTTON1" ]; then
                    BUTTON1_PRESSED=1
                    BUTTON1_TIME=$CURRENT_TIME
                elif [ "$BUTTON" = "$BUTTON2" ]; then
                    BUTTON2_PRESSED=1
                    BUTTON2_TIME=$CURRENT_TIME
                fi

                # Check if both buttons are pressed within the specified timeout
                if [ "$BUTTON1_PRESSED" -eq 1 ] && [ "$BUTTON2_PRESSED" -eq 1 ] && [ $(($CURRENT_TIME - $BUTTON1_TIME)) -le $TIMEOUT ] && [ $(($CURRENT_TIME - $BUTTON2_TIME)) -le $TIMEOUT ]; then
                    echo "Screenshot taken"
                    # Log screenshot action
                    echo "$(date +"%Y-%m-%d %H:%M:%S") - Screenshot taken" >> "$BUTTON_LOG_FILE"
                    take_screenshot
                    BUTTON1_PRESSED=0
                    BUTTON2_PRESSED=0
                fi
            fi
        fi
    fi
  done
}

# Start monitoring
monitor_buttons