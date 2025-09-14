#!/bin/bash

apache2-foreground &

while true; do
  /monitor.sh
  sleep 60
done
