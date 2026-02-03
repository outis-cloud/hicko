#!/bin/bash
# Quick Integration Test Runner
# Run this to validate the entire DNS Manager stack

cd /workspaces/hicko

echo "Setting execute permissions..."
chmod +x run_complete_integration.sh check_backend_connectivity.sh verify_production_readiness.sh 2>/dev/null || true

echo ""
echo "======================================================================"
echo "Hickory DNS Manager - Complete Integration Test"
echo "======================================================================"
echo ""
echo "This script will:"
echo "  1. Start PostgreSQL database"
echo "  2. Build and run the Rust API"
echo "  3. Install and run the React UI"
echo "  4. Execute Playwright E2E tests"
echo "  5. Verify backend connectivity"
echo "  6. Check production readiness"
echo ""
echo "Estimated time: 5-10 minutes"
echo "Logs available in: /tmp/hickory-logs/"
echo ""
echo "======================================================================"
echo ""

bash run_complete_integration.sh
