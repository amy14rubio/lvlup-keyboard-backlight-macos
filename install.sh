#!/bin/zsh
# Builds and installs the backlight toggle as a background service that
# starts automatically every time you log in. Run this once, from wherever
# you've put this folder (Desktop, Downloads, anywhere) - it reads its own
# location automatically, so no path editing is needed.
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "Installing from: $DIR"
echo ""

if [ ! -f "kbled.env" ]; then
  cp "kbled.env.example" "kbled.env"
  echo "Created kbled.env from the example (defaults already match the LVLUP"
  echo "keyboard this was built for). Edit it now if you have a different"
  echo "keyboard or key - see README.md - then re-run this script."
  echo ""
fi

if ! command -v swiftc >/dev/null 2>&1; then
  echo "swiftc (Swift compiler) not found."
  echo "Install the free Xcode Command Line Tools first:"
  echo "    xcode-select --install"
  echo "Then re-run this script."
  exit 1
fi

echo "Building..."
BUILD_TMP=$(mktemp -d)
cp kbled-config.swift "$BUILD_TMP/kbled-config.swift"
cp ledctl.swift "$BUILD_TMP/main.swift"
swiftc "$BUILD_TMP/kbled-config.swift" "$BUILD_TMP/main.swift" -o ledctl
cp kbled-listener.swift "$BUILD_TMP/main.swift"
swiftc "$BUILD_TMP/kbled-config.swift" "$BUILD_TMP/main.swift" -o kbled-listener
rm -rf "$BUILD_TMP"
chmod +x ledctl kbled-listener backlight.sh
echo "Built ledctl and kbled-listener."
echo ""

LABEL="com.kbled.listener"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DIR/kbled-listener</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$DIR/listener.log</string>
    <key>StandardErrorPath</key>
    <string>$DIR/listener.log</string>
</dict>
</plist>
EOF

UID_NUM=$(id -u)
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
sleep 0.3
launchctl bootstrap "gui/$UID_NUM" "$PLIST"

echo "Installed and started the background listener."
echo ""
echo "IMPORTANT - one manual step required by macOS:"
echo "  1. Open System Settings > Privacy & Security > Input Monitoring"
echo "  2. Find 'kbled-listener' in the list and turn it ON"
echo "     (if it's not listed yet, press your trigger key once first -"
echo "     macOS adds it to the list after the first attempt, then you can"
echo "     enable it and re-run this script)"
echo ""
echo "If you use Karabiner-Elements, it may be grabbing this keyboard for"
echo "its own remapping, which will block this tool. See README.md for the"
echo "one-line config change to make Karabiner ignore this keyboard."
echo ""
echo "Once Input Monitoring is enabled, press your trigger key on the"
echo "keyboard - the backlight should toggle. Check $DIR/listener.log if not."
