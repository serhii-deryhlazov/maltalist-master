#!/bin/bash

# Cleanup script - stops and removes production containers and cleans up Docker
# By default, this PRESERVES volumes (including the database)
# Usage: ./cleanup-prod.sh           # Safe: keeps database
#        ./cleanup-prod.sh --volumes  # Dangerous: deletes database!

SERVER_IP="162.0.222.102"
SERVER_USER="root"
DOCKER_PATH="/var/www/docker"

# Parse arguments
DELETE_VOLUMES=false
if [ "$1" = "--volumes" ] || [ "$1" = "-v" ]; then
    DELETE_VOLUMES=true
fi

if [ "$DELETE_VOLUMES" = true ]; then
    echo "⚠️  DANGER: This will PERMANENTLY DELETE the production database!"
    echo "Server: $SERVER_IP"
    echo ""
    echo "This will remove:"
    echo "  - All containers"
    echo "  - All images"
    echo "  - ALL VOLUMES (including database data)"
    echo "  - All build cache"
    echo ""
    echo "THIS ACTION CANNOT BE UNDONE!"
    echo ""
    read -p "Type 'DELETE DATABASE' to confirm: " confirmation

    if [ "$confirmation" != "DELETE DATABASE" ]; then
        echo "Cleanup cancelled."
        exit 0
    fi
else
    echo "⚠️  WARNING: This will stop and remove containers and images on production"
    echo "Server: $SERVER_IP"
    echo ""
    echo "Database volumes will be PRESERVED."
    echo ""
    read -p "Type 'yes' to continue: " confirmation

    if [ "$confirmation" != "yes" ]; then
        echo "Cleanup cancelled."
        exit 0
    fi
fi

echo ""
echo "=== Production Cleanup ==="
echo "=========================="
echo ""

if [ "$DELETE_VOLUMES" = true ]; then
    echo "Stopping and removing all containers AND VOLUMES..."
    ssh $SERVER_USER@$SERVER_IP "cd $DOCKER_PATH && docker-compose -f docker-compose.prod.yml down -v"
else
    echo "Stopping and removing all containers (preserving volumes)..."
    ssh $SERVER_USER@$SERVER_IP "cd $DOCKER_PATH && docker-compose -f docker-compose.prod.yml down"
fi

if [ $? -ne 0 ]; then
    echo "⚠️  Warning: docker-compose down failed or not all containers were running"
fi

echo ""
if [ "$DELETE_VOLUMES" = true ]; then
    echo "Running Docker system prune (including volumes)..."
    ssh $SERVER_USER@$SERVER_IP "docker system prune -a --volumes -f"
else
    echo "Running Docker system prune (preserving volumes)..."
    ssh $SERVER_USER@$SERVER_IP "docker system prune -a -f"
fi

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Docker prune failed"
    exit 1
fi

echo ""
echo "✅ Production cleanup completed successfully!"
echo ""
if [ "$DELETE_VOLUMES" = true ]; then
    echo "All containers, images, volumes, and build cache have been removed."
    echo "⚠️  DATABASE HAS BEEN DELETED!"
else
    echo "All containers, images, and build cache have been removed."
    echo "✓ Database volumes were preserved."
fi
echo "You can now redeploy with fresh containers."
