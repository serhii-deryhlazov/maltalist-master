#!/bin/bash

# Production deployment script - runs on the server
# Usage: ./run-prod.sh api
#        ./run-prod.sh ui
#        ./run-prod.sh db
#        ./run-prod.sh monitoring

DOCKER_PATH="/var/www/docker"
BACKUP_PATH="$DOCKER_PATH/files/backups"
cd $DOCKER_PATH

show_usage() {
    echo "Usage: $0 <MODULE>"
    echo ""
    echo "Modules:"
    echo "  api          Deploy API service"
    echo "  ui           Deploy UI service"
    echo "  db           Deploy database and restore latest backup"
    echo "  monitoring   Deploy monitoring service"
    echo "  -h, --help   Show this help message"
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

echo "=== Production Deployment ==="
echo "Module: $MODULE"
echo "================================"

# Load Docker image if not database deployment
if [ "$MODULE" != "db" ]; then
    echo ""
    echo "Loading Docker image..."
    if [ -f maltalist-$MODULE.tar ]; then
        echo "Loading maltalist-$MODULE.tar..."
        docker load < maltalist-$MODULE.tar
        rm -f maltalist-$MODULE.tar
    fi
fi

# Deploy based on module
echo ""
echo "Deploying $MODULE service..."

if [ "$MODULE" = "api" ]; then
    echo "Restarting API service..."
    docker-compose -f docker-compose.prod.yml up -d --no-deps --force-recreate api
    
    echo "Initializing database..."
    docker-compose -f docker-compose.prod.yml exec -T db /docker-entrypoint-initdb.d/init-db.sh --prod

elif [ "$MODULE" = "ui" ]; then
    echo "Restarting UI service..."
    docker-compose -f docker-compose.prod.yml up -d --no-deps --force-recreate ui

elif [ "$MODULE" = "db" ]; then
    echo "Restarting database service..."
    docker-compose -f docker-compose.prod.yml up -d --no-deps --force-recreate db
    
    # Wait for DB to be ready
    echo "Waiting for database to be ready..."
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose -f docker-compose.prod.yml exec -T db mysqladmin ping -u root -proot >/dev/null 2>&1; then
            echo "✓ Database is ready!"
            break
        fi
        attempt=$((attempt + 1))
        echo "  Waiting for database... ($attempt/$max_attempts)"
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo "❌ Error: Database failed to start properly"
        docker-compose -f docker-compose.prod.yml logs --tail=50 db
        exit 1
    fi
    
    # Initialize database schema
    echo "Initializing database schema..."
    if docker-compose -f docker-compose.prod.yml exec -T db bash /docker-entrypoint-initdb.d/init-db.sh --prod; then
        echo "✓ Database schema initialized successfully"
    else
        echo "❌ Error: Database initialization failed"
        docker-compose -f docker-compose.prod.yml logs --tail=50 db
        exit 1
    fi
    
    # Find and restore latest backup
    echo ""
    echo "Looking for latest backup..."
    LATEST_BACKUP=$(ls -1 $BACKUP_PATH/maltalist_*.sql 2>/dev/null | sort | tail -n 1)
    
    if [ -n "$LATEST_BACKUP" ] && [ -f "$LATEST_BACKUP" ]; then
        echo "Found backup: $(basename $LATEST_BACKUP)"
        echo "Restoring database from backup..."
        if docker-compose -f docker-compose.prod.yml exec -T db mysql -u root -proot maltalist < "$LATEST_BACKUP"; then
            echo "✓ Backup restored successfully"
        else
            echo "⚠ Warning: Backup restore had issues, but database is initialized"
        fi
    else
        echo "⚠ No backup found in $BACKUP_PATH - using initialized schema only"
    fi

elif [ "$MODULE" = "monitoring" ]; then
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
