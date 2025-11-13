#!/bin/bash

# Start PHP-FPM in background
php-fpm81 -D

# Start nginx in background
nginx -g 'daemon off;' &

# Start monitoring loop
while true; do
  /monitor.sh
  sleep 2
done
