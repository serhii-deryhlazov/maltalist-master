#!/bin/bash

# Script to update nginx configuration
# Usage: ./updateProdNginxConf.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONF="$SCRIPT_DIR/prod.nginx.conf"
VPS_USER="root"
VPS_HOST="maltalisting.com"
VPS_NGINX_PATH="/etc/nginx/sites-available/maltalisting.com"

echo "🔄 Uploading nginx configuration to VPS..."
scp "$NGINX_CONF" "$VPS_USER@$VPS_HOST:$VPS_NGINX_PATH"

echo "✅ Configuration uploaded successfully"

echo "🔄 Reloading nginx on VPS..."
ssh "$VPS_USER@$VPS_HOST" "nginx -s reload"

echo "✅ Nginx reloaded successfully"
