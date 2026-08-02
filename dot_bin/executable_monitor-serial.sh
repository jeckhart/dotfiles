#!/bin/sh
# Deliberately no `set -e`: this loop's whole job is to keep retrying after tio exits
# (device unplugged/reconnected), so a nonzero exit from tio must NOT abort the script.

while true; do
	echo "Attempting to connect to serial device..."
	tio --auto-connect new /dev/tty.usb* 115200
	echo "Connection lost. Retrying in 1 second..."
	sleep 1
done
