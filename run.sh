#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <service>"
  echo "Services: db, api, ui, monitor"
  exit 1
fi

service=$1

case $service in
  db|api|ui|monitor)
    echo "Restarting $service..."
    docker-compose restart $service
    ;;
  *)
    echo "Invalid service: $service"
    echo "Valid services: db, api, ui, monitor"
    exit 1
    ;;
esac
