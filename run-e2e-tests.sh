#!/bin/bash

# E2E Test Runner Script
# Starts Docker containers, runs Playwright tests, and cleans up

set -e  # Exit on any error

echo "🚀 Starting E2E Test Suite..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Error: Docker is not running. Please start Docker Desktop."
  exit 1
fi

# Check if containers are already running
if docker compose ps | grep -q "Up"; then
  echo "ℹ️  Docker containers are already running"
  CONTAINERS_WERE_RUNNING=true
else
  echo "📦 Starting Docker containers..."
  CONTAINERS_WERE_RUNNING=false
  
  # Create override file (same as run-dev.sh)
  echo "services: { api: { ports: [] }, db: { ports: [] }, ui: { ports: [\"80:80\", \"443:443\"] } }" > docker-compose.override.yml
  
  # Start containers in detached mode
  docker compose up -d
  
  # Wait for services to be healthy
  echo "⏳ Waiting for services to be ready..."
  sleep 10
  
  # Check if UI is responding
  max_attempts=30
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost > /dev/null 2>&1; then
      echo "✅ Services are ready!"
      break
    fi
    attempt=$((attempt + 1))
    echo "   Waiting for UI to respond... ($attempt/$max_attempts)"
    sleep 2
  done
  
  if [ $attempt -eq $max_attempts ]; then
    echo "❌ Error: Services failed to start properly"
    docker compose logs --tail=50
    exit 1
  fi
fi

echo ""
echo "📝 Ensuring E2E test user exists in database..."
docker exec ml-db-1 mysql -umaltalist_user -p'M@LtApass_Secure_2025!' maltalist -e \
  "INSERT INTO Users (Id, UserName, Email, UserPicture, PhoneNumber, CreatedAt, LastOnline, ConsentTimestamp, IsActive) \
  VALUES ('e2e-test-user-1', 'Test User One', 'testuser1@maltalist.test', \
  '/assets/img/users/test-user-1.jpg', '+356 2123 4567', NOW(), NOW(), NOW(), TRUE) \
  ON DUPLICATE KEY UPDATE UserName='Test User One', IsActive=TRUE;" 2>/dev/null || {
    echo "⚠️  Warning: Could not ensure test user (database may not be ready)"
  }
echo "✅ Test user ready"

echo ""
echo "🧪 Running Playwright E2E tests..."
echo ""

# Navigate to Angular directory and run tests
cd maltalist-angular

# Run tests and capture exit code
if npm run test:e2e; then
  TEST_EXIT_CODE=0
  echo ""
  echo "✅ All E2E tests completed!"
else
  TEST_EXIT_CODE=$?
  echo ""
  echo "❌ Some E2E tests failed (exit code: $TEST_EXIT_CODE)"
fi

# Return to project root
cd ..

# Cleanup only if we started the containers
if [ "$CONTAINERS_WERE_RUNNING" = false ]; then
  echo ""
  echo "🧹 Stopping Docker containers..."
  docker compose down
  echo "✅ Cleanup complete"
else
  echo ""
  echo "ℹ️  Leaving Docker containers running (they were already running before)"
fi

echo ""
echo "📊 Test run finished!"
exit $TEST_EXIT_CODE
