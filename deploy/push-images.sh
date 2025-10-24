#!/bin/bash

# Server configuration
SERVER_IP="162.0.222.102"
SERVER_USER="root"
DOCKER_PATH="/var/www/docker"

# Build all services for linux/amd64 platform
echo "Building services for linux/amd64 platform..."
export DOCKER_DEFAULT_PLATFORM=linux/amd64
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

# Create all directories on server in one SSH command
echo "Creating directories on server..."
ssh $SERVER_USER@$SERVER_IP "mkdir -p $DOCKER_PATH $DOCKER_PATH/files/backups $DOCKER_PATH/files/images $DOCKER_PATH/maltalist-api $DOCKER_PATH/maltalist-angular"

# SCP all files to server
echo "Transferring tar files..."
echo "Uploading maltalist-api.tar..."
scp maltalist-api.tar $SERVER_USER@$SERVER_IP:$DOCKER_PATH/ && echo "maltalist-api.tar transferred successfully"
echo "Uploading maltalist-ui.tar..."
scp maltalist-ui.tar $SERVER_USER@$SERVER_IP:$DOCKER_PATH/ && echo "maltalist-ui.tar transferred successfully"
echo "Uploading maltalist-monitoring.tar..."
scp maltalist-monitoring.tar $SERVER_USER@$SERVER_IP:$DOCKER_PATH/ && echo "maltalist-monitoring.tar transferred successfully"

echo "Transferring config files..."
echo "Uploading docker-compose.prod.yml..."
scp docker-compose.prod.yml $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
echo "Uploading run-prod.sh..."
scp run-prod.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/
echo "Uploading setup-nginx.sh..."
scp setup-nginx.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/

# Copy SSL certificates to server
echo "Setting up SSL certificates on server..."
ssh $SERVER_USER@$SERVER_IP "mkdir -p /etc/ssl/maltalisting.com"
echo "Uploading SSL certificate..."
scp ssl/certificate.crt $SERVER_USER@$SERVER_IP:/etc/ssl/maltalisting.com/certificate.crt
echo "Uploading SSL private key..."
scp ssl/private.key $SERVER_USER@$SERVER_IP:/etc/ssl/maltalisting.com/private.key

# Set proper permissions for SSL certificates
echo "Setting SSL certificate permissions..."
ssh $SERVER_USER@$SERVER_IP "chmod 644 /etc/ssl/maltalisting.com/certificate.crt && chmod 600 /etc/ssl/maltalisting.com/private.key && chown root:root /etc/ssl/maltalisting.com/certificate.crt && chown root:root /etc/ssl/maltalisting.com/private.key"

# Verify files were transferred successfully
echo "Verifying file transfer..."
ssh $SERVER_USER@$SERVER_IP "ls -la $DOCKER_PATH/*.tar"

# Make run-prod.sh executable and copy additional files
echo "Making run-prod.sh executable..."
ssh $SERVER_USER@$SERVER_IP "chmod +x $DOCKER_PATH/run-prod.sh"
echo "Uploading backup.sh..."
scp files/backups/backup.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/files/backups/
echo "Uploading init-db.sh..."
scp maltalist-api/init-db.sh $SERVER_USER@$SERVER_IP:$DOCKER_PATH/maltalist-api/
echo "Uploading nginx.conf..."
scp maltalist-angular/nginx.conf $SERVER_USER@$SERVER_IP:$DOCKER_PATH/maltalist-angular/

# Clean up local tar files only after successful transfer verification
echo "Cleaning up local tar files..."
rm -f maltalist-api.tar maltalist-ui.tar maltalist-monitoring.tar

echo "Images built, tagged, saved as tar files, and uploaded to server."
echo "Production docker-compose.prod.yml and run-prod.sh uploaded."
echo "On the server, run: $DOCKER_PATH/run-prod.sh"