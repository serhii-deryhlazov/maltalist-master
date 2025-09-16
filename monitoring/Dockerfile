FROM php:8.1-apache

RUN apt-get update && apt-get install -y docker.io jq

RUN docker-php-ext-install mysqli

COPY web /var/www/html

COPY scripts/monitor.sh /monitor.sh

RUN chmod +x /monitor.sh

COPY scripts/start.sh /start.sh

RUN chmod +x /start.sh

CMD ["/start.sh"]
