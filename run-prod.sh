#!/bin/bash

# Set up multi-arch emulation for ARM64 images on AMD64 host
echo "Setting up multi-arch emulation..."
docker run --privileged --rm tonistiigi/binfmt --install all

# Load the Docker images from tar files
echo "Loading Docker images..."
docker load < maltalist-api.tar
docker load < maltalist-ui.tar
docker load < maltalist-monitoring.tar

# Run the production docker-compose
echo "Starting services with docker-compose..."
docker compose -f docker-compose.prod.yml up -d

echo "Production deployment complete."
