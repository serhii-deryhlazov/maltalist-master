#!/bin/bash

# Deployment script - builds and uploads a single service to production server
# Usage: ./deploy.sh api
#        ./deploy.sh ui
#        ./deploy.sh db
#        ./deploy.sh monitoring

SERVER_IP="162.0.222.102"
SERVER_USER="root"
DOCKER_PATH="/var/www/docker"
BACKUP_PATH="/var/www/docker/files/backups"

show_usage() {
    echo "Usage: $0 <MODULE>"
    echo ""
    echo "Modules:"
    echo "  api          Deploy API service"
    echo "  ui           Deploy UI service"
    echo "  db           Deploy database and restore latest backup"
    echo "  monitoring   Deploy monitoring service"
    echo "  -h, --help   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 api                      # Deploy only API"
    echo "  $0 ui                       # Deploy only UI"
    echo "  $0 db                       # Deploy DB and restore backup"
    echo "  $0 monitoring               # Deploy monitoring"
}

if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

MODULE="$1"

case $MODULE in
    api|ui|db|monitoring)
        ;;
    -h|--help)
        show_usage
        exit 0
        ;;
    *)
        echo "Error: Unknown module '$MODULE'"
        show_usage
        exit 1
        ;;
esac

echo "=== Deployment Configuration ==="
echo "Module: $MODULE"
echo "================================"

# Go to project root
cd "$(dirname "$0")/.."

# Build and prepare deployment based on module
if [ "$MODULE" != "db" ]; then
    echo ""
    echo "Building $MODULE service for linux/amd64 platform..."
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    
    docker-compose build $MODULE
    
    echo "Saving maltalist-$MODULE image..."
    MODULE_IMAGE=$(docker images --format "{{.Repository}}" | grep $MODULE | head -1)
    docker tag $MODULE_IMAGE maltalist-$MODULE:latest
    docker save maltalist-$MODULE:latest > maltalist-$MODULE.tar
else
    echo ""
    echo "Database deployment - no image build needed"
fi

# Create directories on server
echo ""
echo "Ensuring directories exist on server..."
ssh $SERVER_USER@$SERVER_IP "mkdir -p $DOCKER_PATH $DOCKER_PATH/files/backups $DOCKER_PATH/files/images $DOCKER_PATH/maltalist-api $DOCKER_PATH/maltalist-angular"

# Transfer tar file if not database deployment
echo ""
echo "Transferring files to server..."
if [ "$MODULE" != "db" ]; then
    echo "Uploading maltalist-$MODULE.tar..."
    scp maltalist-$MODULE.tar $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
fi

# Transfer config files
scp docker-compose.prod.yml $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
scp deploy/run-prod.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
ssh $SERVER_USER@$SERVER_IP "chmod +x $DOCKER_PATH/run-prod.sh"

# Transfer supporting files based on module
if [ "$MODULE" = "api" ]; then
    scp maltalist-api/init-db.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/maltalist-api/
elif [ "$MODULE" = "ui" ]; then
    scp maltalist-angular/nginx.conf $SERVER_USER@$SERVER_IP:$DOCKER_PATH/maltalist-angular/
elif [ "$MODULE" = "db" ]; then
    scp files/backups/backup.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/files/backups/
    scp maltalist-api/init-db.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/maltalist-api/
fi

# Clean up local tar files
echo ""
echo "Cleaning up local tar files..."
if [ "$MODULE" != "db" ]; then
    rm -f maltalist-$MODULE.tar
fi

# Run deployment on server
echo ""
echo "Running deployment on server..."
ssh $SERVER_USER@$SERVER_IP "cd $DOCKER_PATH && ./run-prod.sh $MODULE"

echo ""
echo "=== Deployment completed! ==="
