#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <service>"
  echo "Services: db, api, ui, prometheus, grafana, node-exporter, monitoring"
  exit 1
fi

service=$1

case $service in
  db|api|ui)
    echo "Rebuilding and restarting $service..."
    docker-compose build $service
    docker-compose up -d --force-recreate $service
    ;;
  prometheus|grafana|node-exporter)
    echo "Restarting $service..."
    docker-compose up -d --force-recreate $service
    ;;
  monitoring)
    echo "Starting all monitoring services..."
    docker-compose up -d prometheus grafana node-exporter
    ;;
  *)
    echo "Invalid service: $service"
    echo "Valid services: db, api, ui, prometheus, grafana, node-exporter, monitoring"
    exit 1
    ;;
esac
