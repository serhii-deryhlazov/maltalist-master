#!/bin/bash

# Deployment script - builds and uploads selected services to production server
# Usage: ./deploy.sh --api --ui --monitoring
#        ./deploy.sh --all

SERVER_IP="162.0.222.102"
SERVER_USER="root"
DOCKER_PATH="/var/www/docker"

# Parse flags
DEPLOY_API=false
DEPLOY_UI=false
DEPLOY_MONITORING=false

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --api          Deploy API service"
    echo "  --ui           Deploy UI service"
    echo "  --monitoring   Deploy monitoring service"
    echo "  --all          Deploy all services"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --api                    # Deploy only API"
    echo "  $0 --api --ui               # Deploy API and UI"
    echo "  $0 --all                    # Deploy everything"
}

if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --api)
            DEPLOY_API=true
            shift
            ;;
        --ui)
            DEPLOY_UI=true
            shift
            ;;
        --monitoring)
            DEPLOY_MONITORING=true
            shift
            ;;
        --all)
            DEPLOY_API=true
            DEPLOY_UI=true
            DEPLOY_MONITORING=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Build flags to pass to run-prod.sh
RUN_PROD_FLAGS=""
if [ "$DEPLOY_API" = true ]; then RUN_PROD_FLAGS="$RUN_PROD_FLAGS --api"; fi
if [ "$DEPLOY_UI" = true ]; then RUN_PROD_FLAGS="$RUN_PROD_FLAGS --ui"; fi
if [ "$DEPLOY_MONITORING" = true ]; then RUN_PROD_FLAGS="$RUN_PROD_FLAGS --monitoring"; fi

echo "=== Deployment Configuration ==="
echo "API: $DEPLOY_API"
echo "UI: $DEPLOY_UI"
echo "Monitoring: $DEPLOY_MONITORING"
echo "================================"

# Go to project root
cd "$(dirname "$0")/.."

# Build selected services for linux/amd64 platform
echo ""
echo "Building services for linux/amd64 platform..."
export DOCKER_DEFAULT_PLATFORM=linux/amd64

SERVICES_TO_BUILD=""
if [ "$DEPLOY_API" = true ]; then SERVICES_TO_BUILD="$SERVICES_TO_BUILD api"; fi
if [ "$DEPLOY_UI" = true ]; then SERVICES_TO_BUILD="$SERVICES_TO_BUILD ui"; fi
if [ "$DEPLOY_MONITORING" = true ]; then SERVICES_TO_BUILD="$SERVICES_TO_BUILD monitoring"; fi

docker-compose build $SERVICES_TO_BUILD

# Get image names and save to tar files
if [ "$DEPLOY_API" = true ]; then
    echo "Saving maltalist-api image..."
    API_IMAGE=$(docker images --format "{{.Repository}}" | grep api | head -1)
    docker tag $API_IMAGE maltalist-api:latest
    docker save maltalist-api:latest > maltalist-api.tar
fi

if [ "$DEPLOY_UI" = true ]; then
    echo "Saving maltalist-ui image..."
    UI_IMAGE=$(docker images --format "{{.Repository}}" | grep ui | head -1)
    docker tag $UI_IMAGE maltalist-ui:latest
    docker save maltalist-ui:latest > maltalist-ui.tar
fi

if [ "$DEPLOY_MONITORING" = true ]; then
    echo "Saving maltalist-monitoring image..."
    MONITORING_IMAGE=$(docker images --format "{{.Repository}}" | grep monitoring | head -1)
    docker tag $MONITORING_IMAGE maltalist-monitoring:latest
    docker save maltalist-monitoring:latest > maltalist-monitoring.tar
fi

# Create directories on server
echo ""
echo "Ensuring directories exist on server..."
ssh $SERVER_USER@$SERVER_IP "mkdir -p $DOCKER_PATH $DOCKER_PATH/files/backups $DOCKER_PATH/files/images $DOCKER_PATH/maltalist-api $DOCKER_PATH/maltalist-angular"

# Transfer tar files
echo ""
echo "Transferring images to server..."
if [ "$DEPLOY_API" = true ]; then
    echo "Uploading maltalist-api.tar..."
    scp maltalist-api.tar $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
fi

if [ "$DEPLOY_UI" = true ]; then
    echo "Uploading maltalist-ui.tar..."
    scp maltalist-ui.tar $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
fi

if [ "$DEPLOY_MONITORING" = true ]; then
    echo "Uploading maltalist-monitoring.tar..."
    scp maltalist-monitoring.tar $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
fi

# Transfer config files
echo ""
echo "Transferring config files..."
scp docker-compose.prod.yml $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
scp deploy/run-prod.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
ssh $SERVER_USER@$SERVER_IP "chmod +x $DOCKER_PATH/run-prod.sh"

# Transfer supporting files
scp files/backups/backup.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/files/backups/
scp maltalist-api/init-db.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/maltalist-api/
scp maltalist-angular/nginx.conf $SERVER_USER@$SERVER_IP:$DOCKER_PATH/maltalist-angular/

# Clean up local tar files
echo ""
echo "Cleaning up local tar files..."
rm -f maltalist-api.tar maltalist-ui.tar maltalist-monitoring.tar

# Run deployment on server
echo ""
echo "Running deployment on server..."
ssh $SERVER_USER@$SERVER_IP "cd $DOCKER_PATH && ./run-prod.sh $RUN_PROD_FLAGS"

echo ""
echo "=== Deployment completed! ==="
