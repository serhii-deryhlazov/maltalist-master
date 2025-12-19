FROM alpine:3.18

# Install minimal packages including PHP and mysql-client for health checks
RUN apk add --no-cache docker-cli jq nginx bash php81 php81-fpm php81-mysqli php81-json mysql-client

# Setup nginx and PHP-FPM
RUN mkdir -p /var/www/html /var/log/nginx /var/lib/nginx/tmp
COPY web /var/www/html
COPY scripts/monitor.sh /monitor.sh
COPY scripts/start.sh /start.sh

# Create stats directory and set permissions
RUN mkdir -p /var/www/html/stats && \
    chmod -R 755 /var/www/html && \
    chmod 777 /var/www/html/stats

# Create nginx config with PHP support
RUN echo 'server { \
    listen 80; \
    root /var/www/html; \
    index index.php index.html; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_index index.php; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/http.d/default.conf

# Create PHP-FPM config to pass environment variables
RUN mkdir -p /etc/php81/php-fpm.d && \
    echo '[www] \
env[MYSQL_PASSWORD] = $MYSQL_PASSWORD' > /etc/php81/php-fpm.d/env.conf

RUN chmod +x /monitor.sh /start.sh

CMD ["/start.sh"]
