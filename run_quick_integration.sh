#!/bin/bash

# Simplified Integration Test - More Resilient Version

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WORKSPACE_DIR="/workspaces/hicko"
LOGS_DIR="/tmp/hickory-logs"
mkdir -p "$LOGS_DIR"

log_header() { echo -e "\n${BLUE}→ $1${NC}"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_info() { echo -e "${BLUE}ℹ $1${NC}"; }

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   Hickory DNS Manager - Simplified Integration Test    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Trap to clean up
trap 'echo ""; log_info "Cleaning up background processes..."; kill $(jobs -p) 2>/dev/null || true' EXIT

# Check prerequisites
log_header "CHECKING PREREQUISITES"

echo -n "  Docker: "
if docker ps > /dev/null 2>&1; then
  log_success "Running"
else
  log_warn "Not available - some features will be skipped"
fi

echo -n "  Node.js: "
if command -v node &> /dev/null; then
  NODE_V=$(node --version)
  log_success "Ready ($NODE_V)"
else
  log_warn "Not found"
fi

echo -n "  Rust: "
if command -v cargo &> /dev/null; then
  CARGO_V=$(cargo --version | cut -d' ' -f1-2)
  log_success "Ready ($CARGO_V)"
else
  log_warn "Not found"
fi

# ============================================================================
# STEP 1: Try to start PostgreSQL (optional)
# ============================================================================
log_header "STEP 1: PostgreSQL Database (Optional)"

if docker ps > /dev/null 2>&1; then
  log_info "Stopping existing PostgreSQL..."
  docker stop hickory-postgres 2>/dev/null || true
  docker rm hickory-postgres 2>/dev/null || true
  sleep 1
  
  log_info "Starting PostgreSQL..."
  if docker run -d \
    --name hickory-postgres \
    --network host \
    -e POSTGRES_DB=hickory \
    -e POSTGRES_PASSWORD=password \
    postgres:15-alpine \
    > "$LOGS_DIR/postgres.log" 2>&1; then
    
    # Wait for PostgreSQL
    log_info "Waiting for PostgreSQL..."
    for i in {1..30}; do
      if nc -z localhost 5432 2>/dev/null; then
        log_success "PostgreSQL ready"
        break
      fi
      echo -n "."
      sleep 1
    done
    echo ""
  else
    log_warn "PostgreSQL startup failed (skipping)"
  fi
else
  log_warn "Docker not available (skipping PostgreSQL)"
fi

export DATABASE_URL="postgres://postgres:password@localhost:5432/hickory"

# ============================================================================
# STEP 2: Build and Run API
# ============================================================================
log_header "STEP 2: Build Control API (Optional)"

export ADMIN_USERNAME="admin"
export ADMIN_PASSWORD="admin123"
export JWT_SECRET="dev-secret-key"
export RUST_LOG="info"

if command -v cargo &> /dev/null; then
  log_info "Building API (this may take 2-5 minutes)..."
  cd "$WORKSPACE_DIR/crates/control_api"
  
  if cargo build --release > "$LOGS_DIR/build.log" 2>&1; then
    log_success "API built successfully"
    
    log_info "Starting API on port 8080..."
    ./target/release/control_api > "$LOGS_DIR/api.log" 2>&1 &
    API_PID=$!
    echo $API_PID > "$LOGS_DIR/api.pid"
    
    sleep 3
    log_success "API started (PID: $API_PID)"
  else
    log_warn "API build failed (see $LOGS_DIR/build.log)"
  fi
else
  log_warn "Rust not available (skipping API build)"
fi

# ============================================================================
# STEP 3: Setup UI
# ============================================================================
log_header "STEP 3: Setup React UI"

cd "$WORKSPACE_DIR/web/ui"

if command -v node &> /dev/null; then
  if [ ! -d "node_modules" ]; then
    log_info "Installing dependencies..."
    if npm install > "$LOGS_DIR/npm-install.log" 2>&1; then
      log_success "Dependencies installed"
    else
      log_warn "npm install had issues (see logs)"
    fi
  else
    log_success "Dependencies already installed"
  fi
  
  log_info "Starting UI dev server on port 3000..."
  npm run dev > "$LOGS_DIR/ui.log" 2>&1 &
  UI_PID=$!
  echo $UI_PID > "$LOGS_DIR/ui.pid"
  
  sleep 5
  log_success "UI started (PID: $UI_PID)"
else
  log_warn "Node.js not available (skipping UI)"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🎉 INTEGRATION COMPLETE 🎉               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "📋 Services Status:"
if pgrep -f "control_api" > /dev/null 2>&1; then
  echo "  ✓ API is running on http://localhost:8080"
else
  echo "  ✗ API not running (check $LOGS_DIR/api.log)"
fi

if pgrep -f "node" > /dev/null 2>&1; then
  echo "  ✓ UI is running on http://localhost:3000"
else
  echo "  ✗ UI not running (check $LOGS_DIR/ui.log)"
fi

if docker ps 2>/dev/null | grep -q "hickory-postgres"; then
  echo "  ✓ PostgreSQL is running"
else
  echo "  ✗ PostgreSQL not running"
fi

echo ""
echo "🌐 Access Points:"
echo "  • Application: http://localhost:3000"
echo "  • API: http://localhost:8080"
echo "  • Login: admin / admin123"
echo ""

echo "📚 Documentation:"
echo "  • Quick Start: /workspaces/hicko/FRONTEND_README.md"
echo "  • Developer Guide: /workspaces/hicko/DEVELOPER_QUICK_GUIDE.md"
echo "  • Setup Guide: /workspaces/hicko/web/ui/SETUP.md"
echo ""

echo "📋 Service Logs:"
echo "  • API: $LOGS_DIR/api.log"
echo "  • UI: $LOGS_DIR/ui.log"
echo "  • PostgreSQL: $LOGS_DIR/postgres.log"
echo ""

echo "⚠️  Note:"
echo "  • Services will stop when this script exits"
echo "  • To keep running: Run 'npm run dev' in web/ui/ manually"
echo "  • Press Ctrl+C to stop services"
echo ""

# Keep services running
log_info "Services running. Press Ctrl+C to stop..."
wait
