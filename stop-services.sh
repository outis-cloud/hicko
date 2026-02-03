#!/bin/bash

# Stop all Hickory services

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ $1${NC}"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }

LOGS_DIR="/tmp/hickory-logs"

log_info "Stopping Hickory DNS Manager services..."

# Stop API
if [ -f "$LOGS_DIR/api.pid" ]; then
  API_PID=$(cat "$LOGS_DIR/api.pid" 2>/dev/null)
  if kill $API_PID 2>/dev/null; then
    log_success "API stopped (PID: $API_PID)"
  fi
fi

# Stop UI
if [ -f "$LOGS_DIR/ui.pid" ]; then
  UI_PID=$(cat "$LOGS_DIR/ui.pid" 2>/dev/null)
  if kill $UI_PID 2>/dev/null; then
    log_success "UI stopped (PID: $UI_PID)"
  fi
fi

# Stop PostgreSQL
if docker ps 2>/dev/null | grep -q "hickory-postgres"; then
  docker stop hickory-postgres 2>/dev/null && log_success "PostgreSQL stopped"
fi

# Kill any remaining node/cargo processes
pkill -f "npm run dev" 2>/dev/null || true
pkill -f "control_api" 2>/dev/null || true

log_info "All services stopped"
