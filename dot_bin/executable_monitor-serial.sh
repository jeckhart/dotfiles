#!/bin/sh
# Deliberately no `set -e`: this loop's whole job is to keep retrying after tio exits
# (device unplugged/reconnected), so a nonzero exit from tio must NOT abort the script.

if ! command -v tio >/dev/null 2>&1; then
	echo "monitor-serial: tio not found — install it (Brewfile) first" >&2
	exit 1
fi

while true; do
	echo "Attempting to connect to serial device..."
	tio --auto-connect new /dev/tty.usb* 115200
	echo "Connection lost. Retrying in 1 second..."
	sleep 1
done
