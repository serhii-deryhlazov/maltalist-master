#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <service>"
  echo "Services: db, api, ui, monitoring"
  exit 1
fi

service=$1

wait_for_db() {
  echo "⏳ Waiting for database to be ready..."
  max_attempts=30
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    if docker exec ml-db-1 mysqladmin ping -h localhost -umaltalist_user -p'M@LtApass_Secure_2025!' --silent 2>/dev/null; then
      echo "✅ Database is ready!"
      return 0
    fi
    attempt=$((attempt + 1))
    echo "   Waiting... ($attempt/$max_attempts)"
    sleep 2
  done
  echo "❌ Database failed to become ready"
  return 1
}

apply_backup() {
  echo "📦 Looking for latest backup..."
  latest_backup=$(ls -1 files/backups/maltalist_*.sql 2>/dev/null | sort | tail -n 1)
  if [ -f "$latest_backup" ]; then
    echo "📥 Applying backup: $latest_backup"
    docker exec -i ml-db-1 mysql -umaltalist_user -p'M@LtApass_Secure_2025!' maltalist < "$latest_backup" 2>/dev/null
    echo "✅ Backup applied successfully!"
  else
    echo "ℹ️  No backup found, skipping restore"
  fi
}

ensure_test_users() {
  echo "👤 Ensuring E2E test users exist..."
  docker exec ml-db-1 mysql -umaltalist_user -p'M@LtApass_Secure_2025!' maltalist -e \
    "INSERT INTO Users (Id, UserName, Email, UserPicture, PhoneNumber, CreatedAt, LastOnline, ConsentTimestamp, IsActive) VALUES 
    ('e2e-test-user-1', 'Test User One', 'testuser1@maltalist.test', '/assets/img/users/test-user-1.jpg', '+356 2123 4567', NOW(), NOW(), NOW(), TRUE),
    ('e2e-test-user-2', 'Test User Two', 'testuser2@maltalist.test', '/assets/img/users/test-user-2.jpg', '+356 2123 4568', NOW(), NOW(), NOW(), TRUE),
    ('e2e-test-seller', 'Test Seller', 'seller@maltalist.test', '', '+356 9999 8888', NOW(), NOW(), NOW(), TRUE)
    ON DUPLICATE KEY UPDATE IsActive=TRUE;" 2>/dev/null
  echo "✅ Test users ready!"
}

case $service in
  db)
    echo "🔄 Rebuilding and restarting $service..."
    docker-compose build $service
    docker-compose up -d --force-recreate $service
    wait_for_db
    apply_backup
    ensure_test_users
    # Restart API to reconnect to the database
    echo "🔄 Restarting API to reconnect to database..."
    docker-compose restart api
    echo "✅ API restarted!"
    ;;
  api|ui|monitoring)
    echo "🔄 Rebuilding and restarting $service..."
    docker-compose build $service
    docker-compose up -d --force-recreate $service
    ;;
  *)
    echo "Invalid service: $service"
    echo "Valid services: db, api, ui, monitoring"
    exit 1
    ;;
esac

echo ""
echo "✅ Done!"
