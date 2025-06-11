#!/bin/bash

export DISPLAY=${DISPLAY:-:0}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-"unix:path=/run/user/$UID/bus"}

# Pick an image file with zenity
FILE=$(zenity --file-selection --file-filter="Images | *.png *.jpg *.jpeg *.webp")

# Exit if cancelled
[ -z "$FILE" ] && exit 1

# Deletes existing ~/.face & caches
rm -f "$HOME/.face"
rm -f "$HOME/.cache/caelestia/thumbnails/@0x0-exact.png"
rm -f "$HOME/.cache/caelestia/thumbnails/@93x93-exact.png"
rm -f "$HOME/.cache/caelestia/thumbnails/@93x94-exact.png"
rm -f "$HOME/.cache/caelestia/thumbnails/@94x94-exact.png"

cp "$FILE" "$HOME/.face"

echo "$HOME/.face"
