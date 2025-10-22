#!/bin/bash

# Build all services
docker-compose build

# Get image names and tag them
API_IMAGE=$(docker images --format "{{.Repository}}" | grep api | head -1)
UI_IMAGE=$(docker images --format "{{.Repository}}" | grep ui | head -1)
MONITORING_IMAGE=$(docker images --format "{{.Repository}}" | grep monitoring | head -1)

docker tag $API_IMAGE maltalist-api:latest
docker tag $UI_IMAGE maltalist-ui:latest
docker tag $MONITORING_IMAGE maltalist-monitoring:latest

# Save images to tar files
docker save maltalist-api:latest > maltalist-api.tar
docker save maltalist-ui:latest > maltalist-ui.tar
docker save maltalist-monitoring:latest > maltalist-monitoring.tar

# SCP tar files to server
scp maltalist-api.tar root@159.198.65.115:/var/www/docker/
scp maltalist-ui.tar root@159.198.65.115:/var/www/docker/
scp maltalist-monitoring.tar root@159.198.65.115:/var/www/docker/
scp docker-compose.prod.yml root@159.198.65.115:/var/www/docker/
scp run-prod.sh root@159.198.65.115:/var/www/docker/

# Create directories and SCP only required files for mounts
ssh root@159.198.65.115 'mkdir -p /var/www/docker/files /var/www/docker/files/backups /var/www/docker/files/images /var/www/docker/maltalist-api /var/www/docker/maltalist-angular'
scp files/backups/backup.sh root@159.198.65.115:/var/www/docker/files/backups/
scp maltalist-api/init-db.sh root@159.198.65.115:/var/www/docker/maltalist-api/
scp maltalist-angular/nginx.conf root@159.198.65.115:/var/www/docker/maltalist-angular/

echo "Images built, tagged, saved as tar files, and uploaded to server."
echo "Production docker-compose.prod.yml uploaded."
echo "On the server, run: docker load < maltalist-api.tar && docker load < maltalist-ui.tar && docker load < maltalist-monitoring.tar"
echo "Then: docker-compose -f docker-compose.prod.yml up -d"
