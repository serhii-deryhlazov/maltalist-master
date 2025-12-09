#!/bin/bash

# Initialize stats.json if it doesn't exist
if [ ! -f /var/www/html/stats/stats.json ]; then
    echo '[]' > /var/www/html/stats/stats.json
fi

# Ensure proper permissions
chmod 777 /var/www/html/stats/stats.json

# Export environment variables for PHP-FPM
export MYSQL_PASSWORD

# Start PHP-FPM in background with environment variables
php-fpm81 -D

# Start monitoring loop in background
(while true; do
  /monitor.sh
  sleep 2
done) &

# Start nginx in foreground (this keeps the container running)
nginx -g 'daemon off;'
