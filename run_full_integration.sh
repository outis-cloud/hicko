#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Hickory DNS Manager - Full Integration Setup ===${NC}"

# Function to check if service is ready
wait_for_service() {
  local host=$1
  local port=$2
  local name=$3
  local timeout=60
  
  echo -e "${YELLOW}Waiting for $name to be ready ($host:$port)...${NC}"
  for i in $(seq 1 $timeout); do
    if nc -z "$host" "$port" 2>/dev/null; then
      echo -e "${GREEN}✓ $name is ready!${NC}"
      return 0
    fi
    echo -n "."
    sleep 1
  done
  echo -e "${RED}✗ Timeout waiting for $name${NC}"
  return 1
}

# Step 1: Stop any existing services
echo -e "${YELLOW}Step 1: Cleaning up existing containers...${NC}"
docker stop hickory-postgres 2>/dev/null || true
docker rm hickory-postgres 2>/dev/null || true

# Step 2: Start Postgres
echo -e "${YELLOW}Step 2: Starting PostgreSQL database...${NC}"
docker run -d --name hickory-postgres \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15

# Wait for Postgres to be ready
sleep 5
if ! wait_for_service localhost 5432 "PostgreSQL"; then
  echo -e "${RED}Failed to start PostgreSQL${NC}"
  exit 1
fi

# Step 3: Create database
echo -e "${YELLOW}Step 3: Creating hickory database...${NC}"
docker exec hickory-postgres psql -U postgres -c "CREATE DATABASE hickory;" 2>&1 || echo "Database may already exist"

# Step 4: Build control API
echo -e "${YELLOW}Step 4: Building control API...${NC}"
cd /workspaces/hicko
cargo build -p control_api --release 2>&1 | tail -5

# Step 5: Start control API in background
echo -e "${YELLOW}Step 5: Starting control API (background)...${NC}"
export DATABASE_URL="host=127.0.0.1 user=postgres password=password dbname=hickory"
export ADMIN_USERNAME="admin"
export ADMIN_PASSWORD="admin123"
export JWT_SECRET="replace_with_a_super_secret"

./target/release/control_api > /tmp/api.log 2>&1 &
API_PID=$!
echo "API PID: $API_PID"

# Wait for API to be ready
if ! wait_for_service localhost 8080 "Control API"; then
  echo -e "${RED}Failed to start Control API${NC}"
  kill $API_PID 2>/dev/null || true
  exit 1
fi

# Step 6: Build UI and install deps
echo -e "${YELLOW}Step 6: Installing UI dependencies...${NC}"
cd /workspaces/hicko/web/ui
npm install --silent 2>&1 | tail -3

# Step 7: Install Playwright
echo -e "${YELLOW}Step 7: Installing Playwright browsers...${NC}"
npm run e2e:install -- --with-deps 2>&1 | tail -3

# Step 8: Start UI in background
echo -e "${YELLOW}Step 8: Starting UI dev server (background)...${NC}"
npm run dev -- --port 3000 > /tmp/ui.log 2>&1 &
UI_PID=$!
echo "UI PID: $UI_PID"

# Wait for UI to be ready
if ! wait_for_service localhost 3000 "UI"; then
  echo -e "${RED}Failed to start UI${NC}"
  kill $UI_PID 2>/dev/null || true
  kill $API_PID 2>/dev/null || true
  exit 1
fi

# Step 9: Run E2E tests
echo -e "${YELLOW}Step 9: Running Playwright E2E tests...${NC}"
npm run test:e2e 2>&1

TEST_RESULT=$?

# Cleanup
echo -e "${YELLOW}Step 10: Cleaning up...${NC}"
kill $UI_PID 2>/dev/null || true
kill $API_PID 2>/dev/null || true
docker stop hickory-postgres 2>/dev/null || true

if [ $TEST_RESULT -eq 0 ]; then
  echo -e "${GREEN}=== ✓ All tests passed! ===${NC}"
  exit 0
else
  echo -e "${RED}=== ✗ Tests failed ===${NC}"
  echo "API logs:"
  tail -20 /tmp/api.log
  echo -e "\nUI logs:"
  tail -20 /tmp/ui.log
  exit 1
fi
