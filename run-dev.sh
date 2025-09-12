#!/bin/bash
echo "Force killing all containers..."
docker kill $(docker ps -q) 2>/dev/null || true
echo "Force removing all containers..."
docker rm -f $(docker ps -a -q) 2>/dev/null || true
echo "Removing all volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true
echo "override: removing extra ports..."
echo "services: { api: { ports: [] }, db: { ports: [] }, web: { ports: [\"80:80\", \"443:443\"] } }" > docker-compose.override.yml
echo "starting stack..."
docker-compose up --build
