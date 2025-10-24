#!/bin/bash

# Production deployment script
DOCKER_PATH="/var/www/docker"

cd $DOCKER_PATH

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install required dependencies
echo "Checking dependencies..."

if ! command_exists docker; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

if ! command_exists docker-compose; then
    echo "Docker Compose not found. Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
else
    echo "Docker Compose is already installed."
fi

echo "All dependencies are ready."

echo "Loading Docker images..."
echo "Loading maltalist-api.tar..."
docker load < maltalist-api.tar
echo "Loading maltalist-ui.tar..."
docker load < maltalist-ui.tar
echo "Loading maltalist-monitoring.tar..."
docker load < maltalist-monitoring.tar

echo "Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down

echo "Starting new containers..."
docker-compose -f docker-compose.prod.yml up -d

# Setup nginx configuration if not already configured
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
DOMAIN="maltalisting.com"

if [ ! -f "${NGINX_SITES_ENABLED}/${DOMAIN}" ]; then
    echo "Setting up nginx configuration for ${DOMAIN}..."
    
    # Check if nginx is installed
    if ! command_exists nginx; then
        echo "Installing nginx..."
        apt-get update
        apt-get install -y nginx
    fi
    
    # Create nginx configuration
    cat > "${NGINX_SITES_AVAILABLE}/${DOMAIN}" << 'NGINXCONF'
server {
    listen 80;
    server_name maltalisting.com www.maltalisting.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name maltalisting.com www.maltalisting.com;

    # SSL configuration
    ssl_certificate /etc/ssl/maltalisting.com/certificate.crt;
    ssl_certificate_key /etc/ssl/maltalisting.com/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Proxy to UI container
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Proxy API requests to the API container
    location /api/ {
        proxy_pass http://localhost:5023/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/x-javascript
        application/xml+rss
        application/javascript
        application/json;
}
NGINXCONF

    # Create symbolic link to enable the site
    ln -s "${NGINX_SITES_AVAILABLE}/${DOMAIN}" "${NGINX_SITES_ENABLED}/${DOMAIN}"
    echo "Nginx site configuration created and enabled."
    
    # Test nginx configuration
    if nginx -t; then
        echo "Nginx configuration test passed. Reloading nginx..."
        systemctl reload nginx
        echo "Nginx configured successfully for ${DOMAIN}!"
    else
        echo "Warning: Nginx configuration test failed. Please check the configuration manually."
    fi
else
    echo "Nginx configuration for ${DOMAIN} already exists. Skipping..."
fi

echo "Cleaning up tar files..."
rm -f maltalist-api.tar maltalist-ui.tar maltalist-monitoring.tar

echo "Deployment completed successfully!"
docker ps
