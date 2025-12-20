#!/bin/bash

# Cleanup script - stops and removes all production containers and cleans up Docker
# This will DELETE all containers, images, and volumes on the production server
# Usage: ./cleanup-prod.sh

SERVER_IP="162.0.222.102"
SERVER_USER="root"
DOCKER_PATH="/var/www/docker"

echo "⚠️  WARNING: This will stop and remove ALL containers, images, and volumes on production!"
echo "Server: $SERVER_IP"
echo ""
echo "This action cannot be undone!"
echo ""
read -p "Type 'yes' to continue: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "=== Production Cleanup ==="
echo "=========================="
echo ""

echo "Stopping and removing all containers..."
ssh $SERVER_USER@$SERVER_IP "cd $DOCKER_PATH && docker-compose -f docker-compose.prod.yml down -v"

if [ $? -ne 0 ]; then
    echo "⚠️  Warning: docker-compose down failed or not all containers were running"
fi

echo ""
echo "Running Docker system prune..."
ssh $SERVER_USER@$SERVER_IP "docker system prune -a --volumes -f"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Docker prune failed"
    exit 1
fi

echo ""
echo "✅ Production cleanup completed successfully!"
echo ""
echo "All containers, images, volumes, and build cache have been removed."
echo "You can now redeploy with fresh containers."
