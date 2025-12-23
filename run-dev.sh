#!/bin/bash

# Check if dev.env exists
if [ ! -f "dev.env" ]; then
  echo "ERROR: dev.env file not found!"
  echo "Please create dev.env file with required environment variables."
  echo "You can use .env.example as a template."
  exit 1
fi

cleanup() {
  echo "Force killing all containers..."
  docker kill $(docker ps -q) 2>/dev/null || true
  echo "Force removing all containers..."
  docker rm -f $(docker ps -a -q) 2>/dev/null || true
  echo "Removing all volumes..."
  docker volume rm $(docker volume ls -q) 2>/dev/null || true
  
  docker system prune -a --volumes -f
}

cleanup

echo "override: removing extra ports..."
echo "services: { api: { ports: [] }, db: { ports: [] }, ui: { ports: [\"80:80\", \"443:443\"] } }" > docker-compose.override.yml
echo "starting stack..."
docker-compose --env-file dev.env up --build -d

echo "Stack started. Press Ctrl+C to stop and cleanup."
trap "cleanup; exit" INT
tail -f /dev/null