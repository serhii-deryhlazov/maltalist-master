#!/bin/bash

# Check if dev.env exists
if [ ! -f "dev.env" ]; then
  echo "ERROR: dev.env file not found!"
  echo "Please create dev.env file with required environment variables."
  echo "You can use .env.example as a template."
  exit 1
fi

cleanup() {
  echo "Stopping and removing containers and volumes..."
  docker-compose --env-file dev.env down -v 2>/dev/null || true
  echo "Force removing all containers..."
  docker rm -f $(docker ps -a -q) 2>/dev/null || true
  echo "Pruning system..."
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