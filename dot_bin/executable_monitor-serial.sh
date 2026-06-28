#!/bin/sh

while true; do
  echo "Attempting to connect to serial device..."
  tio --auto-connect new /dev/tty.usb* 115200
  echo "Connection lost. Retrying in 1 second..."
  sleep 1
done
              
