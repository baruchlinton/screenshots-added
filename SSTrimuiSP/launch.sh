#!/bin/sh

# Configuración
SCRIPT_NAME="screenshot.sh"
LOG_FILE="/mnt/SDCARD/screenshot.log"
SCRIPT_PATH="/mnt/SDCARD/Apps/Screenshot/$SCRIPT_NAME"
SCREENSHOT_LOG="/mnt/SDCARD/screenshot_captures.log"

# Función para mostrar mensajes en el log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Función para mostrar notificaciones visuales
show_notification() {
    local message="$1"
    # Mostrar la notificación
    sdl2imgshow \
        -i "/mnt/SDCARD/Apps/MyIP/bg.png" \
        -f "/mnt/SDCARD/Apps/MyIP/font.ttf" \
        -s 45 \
        -c "255,0,0" \
        -t "$message" &
    
    # Guardar el PID del proceso sdl2imgshow
    local NOTIFICATION_PID=$!

    # Esperar 3 segundos
    sleep 3

    # Cerrar la notificación
    if kill -0 "$NOTIFICATION_PID" 2>/dev/null; then
        kill "$NOTIFICATION_PID"
    fi
}

# Verificar si el script ya está en ejecución
if pgrep -f "$SCRIPT_PATH" > /dev/null; then
    log_message "$SCRIPT_NAME ya está en ejecución. Deteniendo el proceso..."
    pkill -f "$SCRIPT_PATH"
    show_notification "Captura de pantalla detenida"
    exit 0
else
    log_message "$SCRIPT_NAME no está en ejecución. Iniciando ahora..."
    show_notification "Captura de pantalla en ejecución"
    /bin/sh "$SCRIPT_PATH" &
fi