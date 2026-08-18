#!/bin/zsh
# Manually toggles the keyboard backlight from the command line.
# Usage: ./backlight.sh on|off|toggle
#
# The background listener (kbled-listener, installed by install.sh) is what
# makes your trigger key do this automatically - this script is just for
# manual use, and reads the same kbled.env config so both stay in sync.

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$DIR/.state"
ON_VALUE=$(grep '^KBLED_LED_ON_VALUE=' "$DIR/kbled.env" | cut -d= -f2)

case "$1" in
  on)  VALUE="$ON_VALUE"; NEW=on ;;
  off) VALUE=00; NEW=off ;;
  toggle)
    LAST=$(cat "$STATE_FILE" 2>/dev/null || echo off)
    if [ "$LAST" = "on" ]; then VALUE=00; NEW=off; else VALUE="$ON_VALUE"; NEW=on; fi
    ;;
  *) echo "Usage: $0 on|off|toggle"; exit 1 ;;
esac

"$DIR/ledctl" "$VALUE"

echo "$NEW" > "$STATE_FILE"
