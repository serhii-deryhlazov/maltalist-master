#!/bin/bash

# Production deployment script - runs on the server
# Usage: ./run-prod.sh --api --ui --monitoring
#        ./run-prod.sh --all

DOCKER_PATH="/var/www/docker"
cd $DOCKER_PATH

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

echo "=== Deployment Configuration ==="
echo "API: $DEPLOY_API"
echo "UI: $DEPLOY_UI"
echo "Monitoring: $DEPLOY_MONITORING"
echo "================================"

# Load Docker images
echo ""
echo "Loading Docker images..."
if [ "$DEPLOY_API" = true ] && [ -f maltalist-api.tar ]; then
    echo "Loading maltalist-api.tar..."
    docker load < maltalist-api.tar
    rm -f maltalist-api.tar
fi

if [ "$DEPLOY_UI" = true ] && [ -f maltalist-ui.tar ]; then
    echo "Loading maltalist-ui.tar..."
    docker load < maltalist-ui.tar
    rm -f maltalist-ui.tar
fi

if [ "$DEPLOY_MONITORING" = true ] && [ -f maltalist-monitoring.tar ]; then
    echo "Loading maltalist-monitoring.tar..."
    docker load < maltalist-monitoring.tar
    rm -f maltalist-monitoring.tar
fi

# Gracefully restart selected services
echo ""
echo "Restarting services..."

if [ "$DEPLOY_API" = true ]; then
    echo "Restarting API service..."
    docker-compose -f docker-compose.prod.yml up -d --no-deps --force-recreate api
fi

if [ "$DEPLOY_UI" = true ]; then
    echo "Restarting UI service..."
    docker-compose -f docker-compose.prod.yml up -d --no-deps --force-recreate ui
fi

if [ "$DEPLOY_MONITORING" = true ]; then
    echo "Restarting Monitoring service..."
    docker-compose -f docker-compose.prod.yml up -d --no-deps --force-recreate monitoring
fi

# Clean up old images
echo ""
echo "Cleaning up dangling images..."
docker image prune -f

echo ""
echo "=== Deployment completed successfully! ==="
echo ""
docker ps
