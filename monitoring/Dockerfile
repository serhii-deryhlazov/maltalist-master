FROM alpine:3.18

# Install minimal packages
RUN apk add --no-cache docker-cli jq nginx bash

# Setup nginx
RUN mkdir -p /var/www/html /var/log/nginx /var/lib/nginx/tmp
COPY web /var/www/html
COPY scripts/monitor.sh /monitor.sh
COPY scripts/start.sh /start.sh

# Create nginx config
RUN echo 'server { \
    listen 80; \
    root /var/www/html; \
    index index.html index.php; \
    location / { try_files $uri $uri/ =404; } \
}' > /etc/nginx/http.d/default.conf

RUN chmod +x /monitor.sh /start.sh

CMD ["/start.sh"]
