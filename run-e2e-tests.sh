#!/bin/bash

# E2E Test Runner Script
# Starts Docker containers, runs Playwright tests, and cleans up

set -e  # Exit on any error

# Record start time
START_TIME=$(date +%s)

echo "🚀 Starting E2E Test Suite..."
echo ""

# Check if dev.env exists
if [ ! -f "dev.env" ]; then
  echo "❌ Error: dev.env file not found!"
  echo "Please create dev.env file with required environment variables."
  exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Error: Docker is not running. Please start Docker Desktop."
  exit 1
fi

# Check if containers are already running
if docker compose --env-file dev.env ps | grep -q "Up"; then
  echo "ℹ️  Docker containers are already running"
  CONTAINERS_WERE_RUNNING=true
else
  echo "📦 Starting Docker containers..."
  CONTAINERS_WERE_RUNNING=false
  
  # Create override file (same as run-dev.sh)
  echo "services: { api: { ports: [] }, db: { ports: [] }, ui: { ports: [\"80:80\", \"443:443\"] } }" > docker-compose.override.yml
  
  # Start containers in detached mode with dev.env
  docker compose --env-file dev.env up -d
  
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
echo "🧪 Running Playwright E2E tests..."
echo ""

# Navigate to Angular directory and run tests
cd maltalist-angular

# Run tests and capture output (disable exit-on-error temporarily)
set +e
TEST_OUTPUT=$(npm run test:e2e 2>&1)
TEST_EXIT_CODE=$?
set -e

# Display the output
echo "$TEST_OUTPUT"

# Extract and display failed tests summary
if [ $TEST_EXIT_CODE -ne 0 ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ FAILED TESTS SUMMARY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Extract failed test list from output
  echo "$TEST_OUTPUT" | grep -A 1000 "failed$" | grep "^\s*\[" | sort -u || echo "  (Could not parse failed tests list)"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "❌ Some E2E tests failed (exit code: $TEST_EXIT_CODE)"
else
  echo ""
  echo "✅ All E2E tests passed!"
fi

# Return to project root
cd ..

# Clean up test data created during E2E tests
echo ""
echo "🧹 Cleaning up test data..."

# Get list of test listing IDs before deletion
TEST_LISTING_IDS=$(docker exec ml-db-1 mysql -u root -p'Complex_Root_Pass_2025!' maltalist -N -e "SELECT Id FROM Listings WHERE UserId LIKE 'e2e-%';" 2>/dev/null || true)

# Delete listings from database
docker exec ml-db-1 mysql -u root -p'Complex_Root_Pass_2025!' maltalist -e "DELETE FROM Listings WHERE UserId LIKE 'e2e-%';" 2>/dev/null || echo "  (Could not clean up test listings)"

# Remove test image folders
if [ -d "./files/images/listings" ]; then
  for listing_id in $TEST_LISTING_IDS; do
    if [ -d "./files/images/listings/$listing_id" ]; then
      rm -rf "./files/images/listings/$listing_id"
      echo "  ✓ Removed image folder for listing $listing_id"
    fi
  done
  echo "✅ Test listing image folders cleaned up"
fi

echo "✅ Test data cleaned up"

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

# Calculate and display execution time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "📊 Test run finished!"
echo "⏱️  Total time: ${MINUTES}m ${SECONDS}s"
exit $TEST_EXIT_CODE
