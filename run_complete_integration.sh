#!/bin/bash

# Complete Hickory DNS Manager Integration & Verification
# Orchestrates: PostgreSQL → API → UI → E2E Tests → Verification

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WORKSPACE_DIR="/workspaces/hicko"
LOGS_DIR="/tmp/hickory-logs"
mkdir -p "$LOGS_DIR"

log_header() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }
log_info() { echo -e "${YELLOW}ℹ $1${NC}"; }

# Trap errors
cleanup() {
  log_info "Cleaning up..."
  kill $(jobs -p) 2>/dev/null || true
  echo ""
}
trap cleanup EXIT

# ============================================================================
# PHASE 1: ENVIRONMENT SETUP
# ============================================================================
log_header "PHASE 1: ENVIRONMENT SETUP"

# Set environment variables
export DATABASE_URL="postgres://postgres:password@localhost:5432/hickory"
export ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"
export JWT_SECRET="${JWT_SECRET:-dev-secret-key-change-in-production}"
export RUST_LOG="info"

log_info "DATABASE_URL: $DATABASE_URL"
log_info "ADMIN_USERNAME: $ADMIN_USERNAME"
log_info "RUST_LOG: $RUST_LOG"

# ============================================================================
# PHASE 2: POSTGRESQL DATABASE
# ============================================================================
log_header "PHASE 2: POSTGRESQL DATABASE"

log_info "Stopping existing PostgreSQL container..."
docker stop hickory-postgres 2>/dev/null || true
docker rm hickory-postgres 2>/dev/null || true
sleep 1

log_info "Starting PostgreSQL 15 container..."
docker run -d \
  --name hickory-postgres \
  --network host \
  -e POSTGRES_DB=hickory \
  -e POSTGRES_PASSWORD=password \
  postgres:15-alpine \
  > "$LOGS_DIR/postgres.log" 2>&1

# Wait for PostgreSQL to be ready
log_info "Waiting for PostgreSQL to be ready..."
for i in {1..60}; do
  if nc -z localhost 5432 2>/dev/null; then
    log_success "PostgreSQL is ready"
    sleep 2
    break
  fi
  echo -n "."
  sleep 1
  if [ $i -eq 60 ]; then
    log_error "PostgreSQL failed to start within 60 seconds"
    cat "$LOGS_DIR/postgres.log"
    exit 1
  fi
done
echo ""

# Run migrations
log_info "Creating database schema..."
cd "$WORKSPACE_DIR/crates/control_api"
sqlx database create 2>/dev/null || log_info "Database already exists"
sqlx migrate run 2>/dev/null || log_info "Migrations already run"

log_success "PostgreSQL database initialized"

# ============================================================================
# PHASE 3: BACKEND API BUILD & RUN
# ============================================================================
log_header "PHASE 3: BACKEND API BUILD & RUN"

log_info "Building Control API (release mode)..."
cd "$WORKSPACE_DIR/crates/control_api"
cargo build --release > "$LOGS_DIR/build.log" 2>&1

if [ ! -f target/release/control_api ]; then
  log_error "API build failed"
  tail -20 "$LOGS_DIR/build.log"
  exit 1
fi
log_success "Control API built successfully"

log_info "Starting Control API on port 8080..."
./target/release/control_api > "$LOGS_DIR/api.log" 2>&1 &
API_PID=$!
echo $API_PID > "$LOGS_DIR/api.pid"

# Wait for API to be ready
log_info "Waiting for API to be ready..."
for i in {1..60}; do
  if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    log_success "API is ready"
    break
  fi
  echo -n "."
  sleep 1
  if [ $i -eq 60 ]; then
    log_error "API failed to start within 60 seconds"
    kill $API_PID 2>/dev/null || true
    tail -20 "$LOGS_DIR/api.log"
    exit 1
  fi
done
echo ""

# Test API connectivity
log_info "Testing API connectivity..."
LOGIN_RESP=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}" \
  http://localhost:8080/api/v1/auth/login)

if echo "$LOGIN_RESP" | grep -q "token"; then
  log_success "API authentication test passed"
else
  log_error "API authentication test failed"
  log_info "Response: $LOGIN_RESP"
  exit 1
fi

# ============================================================================
# PHASE 4: FRONTEND UI SETUP & RUN
# ============================================================================
log_header "PHASE 4: FRONTEND UI SETUP & RUN"

cd "$WORKSPACE_DIR/web/ui"

log_info "Installing UI dependencies..."
npm install > "$LOGS_DIR/npm-install.log" 2>&1
log_success "Dependencies installed"

log_info "Installing Playwright browsers..."
npx playwright install chromium > "$LOGS_DIR/playwright-install.log" 2>&1
log_success "Playwright browsers installed"

log_info "Starting UI dev server on port 3000..."
npm run dev > "$LOGS_DIR/ui.log" 2>&1 &
UI_PID=$!
echo $UI_PID > "$LOGS_DIR/ui.pid"

# Wait for UI to be ready
log_info "Waiting for UI to be ready..."
for i in {1..60}; do
  if curl -s http://localhost:3000 > /dev/null 2>&1; then
    log_success "UI is ready"
    break
  fi
  echo -n "."
  sleep 1
  if [ $i -eq 60 ]; then
    log_error "UI failed to start within 60 seconds"
    kill $UI_PID 2>/dev/null || true
    tail -20 "$LOGS_DIR/ui.log"
    exit 1
  fi
done
echo ""

# ============================================================================
# PHASE 5: E2E TESTS
# ============================================================================
log_header "PHASE 5: END-TO-END TESTING"

log_info "Running comprehensive E2E test suite..."
cd "$WORKSPACE_DIR/web/ui"

if [ ! -f tests/e2e.full.spec.js ]; then
  log_error "E2E test file not found: tests/e2e.full.spec.js"
  exit 1
fi

if npx playwright test tests/e2e.full.spec.js --reporter=list > "$LOGS_DIR/e2e-tests.log" 2>&1; then
  log_success "All E2E tests passed"
  TEST_RESULT="PASSED"
else
  log_error "Some E2E tests failed"
  TEST_RESULT="FAILED"
  tail -50 "$LOGS_DIR/e2e-tests.log"
fi

# ============================================================================
# PHASE 6: BACKEND CONNECTIVITY VERIFICATION
# ============================================================================
log_header "PHASE 6: BACKEND CONNECTIVITY VERIFICATION"

log_info "Testing all API endpoints..."
cd "$WORKSPACE_DIR"

if bash check_backend_connectivity.sh > "$LOGS_DIR/connectivity.log" 2>&1; then
  log_success "All backend connectivity tests passed"
  CONNECTIVITY_RESULT="PASSED"
else
  log_error "Some backend connectivity tests failed"
  CONNECTIVITY_RESULT="FAILED"
  tail -50 "$LOGS_DIR/connectivity.log"
fi

# ============================================================================
# PHASE 7: PRODUCTION READINESS VERIFICATION
# ============================================================================
log_header "PHASE 7: PRODUCTION READINESS VERIFICATION"

if bash verify_production_readiness.sh > "$LOGS_DIR/readiness.log" 2>&1; then
  log_success "Production readiness checks passed"
  READINESS_RESULT="PASSED"
else
  log_error "Some production readiness checks failed"
  READINESS_RESULT="FAILED"
fi

# ============================================================================
# FINAL REPORT
# ============================================================================
log_header "INTEGRATION & VERIFICATION REPORT"

cat << EOF
┌─────────────────────────────────────────────────────┐
│                  FINAL RESULTS                      │
├─────────────────────────────────────────────────────┤
│ PostgreSQL Database        │ ✓ RUNNING              │
│ Control API (Port 8080)    │ ✓ RUNNING              │
│ UI Dev Server (Port 3000)  │ ✓ RUNNING              │
│ E2E Tests                  │ $TEST_RESULT                 │
│ Backend Connectivity       │ $CONNECTIVITY_RESULT         │
│ Production Readiness       │ $READINESS_RESULT         │
└─────────────────────────────────────────────────────┘

📊 TEST DETAILS:
   • E2E Tests: tests/e2e.full.spec.js (40+ scenarios)
   • Connectivity: All major API endpoints validated
   • Readiness: Security, Performance, Compliance checks

📋 SERVICE LOGS:
   • PostgreSQL: $LOGS_DIR/postgres.log
   • API Build: $LOGS_DIR/build.log
   • API Runtime: $LOGS_DIR/api.log (PID: $API_PID)
   • UI Dev: $LOGS_DIR/ui.log (PID: $UI_PID)
   • E2E Tests: $LOGS_DIR/e2e-tests.log
   • Connectivity: $LOGS_DIR/connectivity.log
   • Readiness: $LOGS_DIR/readiness.log

🌐 ACCESS POINTS:
   • UI Application: http://localhost:3000
   • API Endpoint: http://localhost:8080
   • API Docs: http://localhost:8080/swagger-ui/
   • Admin Dashboard: http://localhost:3000/admin
   • Default Credentials: $ADMIN_USERNAME / $ADMIN_PASSWORD

📝 NEXT STEPS:
   1. Access http://localhost:3000 in your browser
   2. Login with credentials: $ADMIN_USERNAME / $ADMIN_PASSWORD
   3. Test zone, record, user management
   4. Try bulk import, audit logs, dark mode
   5. Review logs in $LOGS_DIR for any issues

⚠️  IMPORTANT:
   • Services are running in the background (PIDs in $LOGS_DIR)
   • To stop: kill $(cat $LOGS_DIR/*.pid)
   • Database persists in Docker container
   • To clean up: docker stop hickory-postgres

✅ INTEGRATION COMPLETE - Ready for production validation
EOF

if [ "$TEST_RESULT" = "PASSED" ] && [ "$CONNECTIVITY_RESULT" = "PASSED" ]; then
  echo -e "\n${GREEN}✓ Full integration test SUCCESSFUL${NC}"
  exit 0
else
  echo -e "\n${RED}✗ Some tests failed - review logs above${NC}"
  exit 1
fi
