#!/bin/zsh
# Stops and removes the background listener. Leaves this folder (and its
# binaries/config) in place - delete it yourself if you want it fully gone.
LABEL="com.kbled.listener"
UID_NUM=$(id -u)
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
echo "Stopped and unregistered the background listener."
