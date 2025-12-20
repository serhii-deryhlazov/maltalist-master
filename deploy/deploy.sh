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

# Load production environment variables
if [ -f "prod.env" ]; then
    echo "Loading environment variables from prod.env..."
    set -a  # Automatically export all variables
    source prod.env
    set +a
else
    echo "⚠️  Warning: prod.env file not found"
fi

# Basic validation
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed"
    exit 1
fi

# Build and prepare deployment based on module
if [ "$MODULE" != "db" ]; then
    echo ""
    echo "Building $MODULE service for linux/amd64 platform..."
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    
    docker-compose build $MODULE
    BUILD_EXIT_CODE=$?
    
    if [ $BUILD_EXIT_CODE -ne 0 ]; then
        echo "❌ BUILD FAILED: docker-compose build exited with code $BUILD_EXIT_CODE"
        exit $BUILD_EXIT_CODE
    fi
    
    echo "Saving maltalist-$MODULE image..."
    MODULE_IMAGE=$(docker images --format "{{.Repository}}" | grep $MODULE | head -1)
    
    if [ -z "$MODULE_IMAGE" ]; then
        echo ""
        echo "❌ ERROR: Could not find built image for $MODULE"
        echo "Image search returned empty. Build may have failed silently."
        exit 1
    fi
    
    docker tag $MODULE_IMAGE maltalist-$MODULE:latest
    TAG_EXIT_CODE=$?
    
    if [ $TAG_EXIT_CODE -ne 0 ]; then
        echo ""
        echo "❌ ERROR: Failed to tag image with exit code $TAG_EXIT_CODE"
        exit $TAG_EXIT_CODE
    fi
    
    docker save maltalist-$MODULE:latest > maltalist-$MODULE.tar
    SAVE_EXIT_CODE=$?
    
    if [ $SAVE_EXIT_CODE -ne 0 ]; then
        echo ""
        echo "❌ ERROR: Failed to save image with exit code $SAVE_EXIT_CODE"
        rm -f maltalist-$MODULE.tar
        exit $SAVE_EXIT_CODE
    fi
else
    echo ""
    echo "Database deployment - no image build needed"
fi

# Create directories on server
echo ""
echo "Ensuring directories exist on server..."
ssh $SERVER_USER@$SERVER_IP "mkdir -p $DOCKER_PATH $DOCKER_PATH/files/backups $DOCKER_PATH/files/images $DOCKER_PATH/maltalist-api $DOCKER_PATH/maltalist-angular"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to create directories on server"
    exit 1
fi

# Transfer tar file if not database deployment
echo ""
echo "Transferring files to server..."
if [ "$MODULE" != "db" ]; then
    if [ ! -f "maltalist-$MODULE.tar" ]; then
        echo "❌ ERROR: maltalist-$MODULE.tar not found"
        exit 1
    fi
    echo "Uploading maltalist-$MODULE.tar..."
    scp maltalist-$MODULE.tar $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Failed to upload maltalist-$MODULE.tar"
        exit 1
    fi
fi

# Transfer config files
scp docker-compose.prod.yml $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to upload docker-compose.prod.yml"
    exit 1
fi

scp prod.env $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to upload prod.env"
    exit 1
fi

scp deploy/run-prod.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to upload run-prod.sh"
    exit 1
fi

ssh $SERVER_USER@$SERVER_IP "chmod +x $DOCKER_PATH/run-prod.sh"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to set permissions on run-prod.sh"
    exit 1
fi

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
    if [ -f "maltalist-$MODULE.tar" ]; then
        rm -f maltalist-$MODULE.tar
        if [ $? -ne 0 ]; then
            echo "⚠️  WARNING: Failed to clean up maltalist-$MODULE.tar"
        fi
    fi
fi

# Run deployment on server
echo ""
echo "Running deployment on server..."
ssh $SERVER_USER@$SERVER_IP "cd $DOCKER_PATH && ./run-prod.sh $MODULE"
DEPLOYMENT_EXIT_CODE=$?

if [ $DEPLOYMENT_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ ERROR: Deployment on server failed with exit code $DEPLOYMENT_EXIT_CODE"
    exit $DEPLOYMENT_EXIT_CODE
fi

echo ""
echo "✅ Deployment completed successfully!"
