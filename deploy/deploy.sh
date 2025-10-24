#!/bin/bash

# setup-nginx.sh - Configure nginx for maltalisting.com domain

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
DOMAIN="maltalisting.com"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
UI_PORT="8080"
API_PORT="5023"

echo -e "${GREEN}Setting up nginx configuration for ${DOMAIN}${NC}"

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}Error: nginx is not installed${NC}"
    exit 1
fi

# Create the nginx configuration file
echo -e "${YELLOW}Creating nginx configuration for ${DOMAIN}${NC}"

cat > "${NGINX_SITES_AVAILABLE}/${DOMAIN}" << 'EOF'
server {
    listen 80;
    server_name maltalisting.com www.maltalisting.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name maltalisting.com www.maltalisting.com;

    # SSL configuration (update paths as needed)
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
EOF

echo -e "${GREEN}Configuration file created at ${NGINX_SITES_AVAILABLE}/${DOMAIN}${NC}"

# Create symbolic link to enable the site
echo -e "${YELLOW}Enabling the site...${NC}"
if [ ! -f "${NGINX_SITES_ENABLED}/${DOMAIN}" ]; then
    ln -s "${NGINX_SITES_AVAILABLE}/${DOMAIN}" "${NGINX_SITES_ENABLED}/${DOMAIN}"
    echo -e "${GREEN}Site enabled successfully${NC}"
else
    echo -e "${YELLOW}Site is already enabled${NC}"
fi

# Test nginx configuration
echo -e "${YELLOW}Testing nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration test passed${NC}"
    
    # Reload nginx
    echo -e "${YELLOW}Reloading nginx...${NC}"
    systemctl reload nginx
    echo -e "${GREEN}Nginx reloaded successfully${NC}"
    
    echo -e "${GREEN}Setup completed successfully!${NC}"
    echo -e "${YELLOW}Your site should now be accessible at:${NC}"
    echo -e "  - http://${DOMAIN} (redirects to HTTPS)"
    echo -e "  - https://${DOMAIN}"
    echo -e ""
    echo -e "${YELLOW}Note: Make sure your SSL certificates are properly configured at:${NC}"
    echo -e "  - /etc/ssl/certs/maltalisting.com.crt"
    echo -e "  - /etc/ssl/private/maltalisting.com.key"
    echo -e ""
    echo -e "${YELLOW}Also ensure your Docker containers are running:${NC}"
    echo -e "  - UI container on port ${UI_PORT}"
    echo -e "  - API container on port ${API_PORT}"
else
    echo -e "${RED}Nginx configuration test failed${NC}"
    echo -e "${RED}Please check the configuration and try again${NC}"
    exit 1
fi