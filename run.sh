#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <service>"
  echo "Services: db, api, ui, monitoring"
  exit 1
fi

service=$1

case $service in
  db|api|ui|monitoring)
    echo "Rebuilding and restarting $service..."
    docker-compose build $service
    docker-compose up -d --force-recreate $service
    ;;
  *)
    echo "Invalid service: $service"
    echo "Valid services: db, api, ui, monitoring"
    exit 1
    ;;
esac
