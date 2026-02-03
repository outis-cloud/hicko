# Integration Scripts - Final Setup

## Master Scripts Created

### 1. **integrate.sh** - Comprehensive Integration
The main production integration script that does everything:
- Checks all prerequisites (Docker, Node.js, Rust)
- Exits with clear error if requirements not met
- Starts PostgreSQL database
- Builds Rust API in release mode
- Installs UI dependencies
- Starts UI dev server
- Optionally runs E2E tests
- Shows final status report

**Usage:**
```bash
bash integrate.sh
```

**Expected Output:**
```
╔════════════════════════════════════════════════════════╗
║    Hickory DNS Manager - Full Integration Test        ║
║         PostgreSQL | API | UI | E2E Tests             ║
╚════════════════════════════════════════════════════════╝

✓ Docker: Available and running
✓ Node.js: Installed (v18.x.x)
✓ Rust: Installed (cargo 1.x.x)

[PostgreSQL setup...]
✓ PostgreSQL container started
✓ PostgreSQL is ready

[API build...]
✓ API built successfully
✓ API process started (PID: xxxx)
✓ API is ready

[UI setup...]
✓ Dependencies installed
✓ UI process started (PID: xxxx)
✓ UI is ready

✓ INTEGRATION COMPLETE

Services are running:
  ✓ API running on http://localhost:8080
  ✓ UI running on http://localhost:3000
  ✓ PostgreSQL running on localhost:5432

Access the application:
  URL: http://localhost:3000
  Username: admin
  Password: admin123
```

### 2. **run_quick_integration.sh** - Fast Development Mode
Lighter alternative for rapid development:
- Graceful error handling (doesn't fail on missing services)
- Useful for iterative development
- Skips services that aren't available

**Usage:**
```bash
bash run_quick_integration.sh
```

### 3. **stop-services.sh** - Clean Shutdown
Stops all running services:
- Kills API process
- Kills UI dev server
- Stops PostgreSQL container
- Cleans up stray processes

**Usage:**
```bash
bash stop-services.sh
```

## Key Files Consolidated

### Removed (Redundant):
- `run_complete_integration.sh` - Too verbose, replaced by `integrate.sh`
- `run_full_integration.sh` - Duplicate, replaced by `integrate.sh`
- `start_integration_test.sh` - Redundant helper

### Kept (Essential):
- `integrate.sh` - Master integration script
- `run_quick_integration.sh` - Quick dev mode
- `stop-services.sh` - Service manager
- `check_system.sh` - Prerequisite checker
- `check_backend_connectivity.sh` - API validator
- `verify_production_readiness.sh` - Production checker

## Documentation Created

1. **INTEGRATION.md** - How to use the scripts
2. **INTEGRATION_TROUBLESHOOTING.md** - Problem solving guide
3. This file - Overview of changes

## Service Architecture

The `integrate.sh` script orchestrates:

```
integrate.sh (entry point)
    ↓
PHASE 1: Prerequisites Check
    ├─ Docker available? (exit if no)
    ├─ Node.js installed? (exit if no)
    ├─ Rust installed? (exit if no)
    └─ psql installed? (optional)
    ↓
PHASE 2: PostgreSQL Setup
    ├─ Stop existing container
    ├─ Start new PostgreSQL container
    ├─ Wait for port 5432 to respond
    └─ Database ready at: postgresql://postgres:password@localhost:5432/hickory
    ↓
PHASE 3: API Build & Run
    ├─ Build: cargo build --release (3-5 min first run)
    ├─ Start: ./target/release/control_api
    ├─ Wait for /health endpoint
    └─ API ready at: http://localhost:8080
    ↓
PHASE 4: UI Setup & Run
    ├─ npm install (2-3 min if needed)
    ├─ npm run dev
    ├─ Wait for http://localhost:3000
    └─ UI ready at: http://localhost:3000
    ↓
PHASE 5: E2E Tests (Optional)
    ├─ Runs Playwright test suite
    ├─ 40+ test scenarios
    └─ Results logged to /tmp/hickory-logs/e2e-tests.log
    ↓
Final Status Report
    ├─ Service health check
    ├─ Access instructions
    ├─ Log file locations
    └─ Stop instructions
```

## Environment Variables Set

The script automatically sets:

```bash
DATABASE_URL="postgres://postgres:password@localhost:5432/hickory"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin123"
JWT_SECRET="dev-secret-key-change-in-production"
RUST_LOG="info"
```

## Log Files

All logs saved to `/tmp/hickory-logs/`:
- `api.log` - Rust API output
- `ui.log` - Node.js dev server output
- `postgres.log` - PostgreSQL startup
- `build.log` - Cargo build output
- `npm-install.log` - npm install output
- `e2e-tests.log` - Playwright test results

## Typical Execution Times

**First Run:**
- Prerequisites check: 5 seconds
- PostgreSQL startup: 10-15 seconds
- API build: 3-5 minutes
- npm install: 1-2 minutes
- UI startup: 10-20 seconds
- **Total: ~10-15 minutes**

**Subsequent Runs:**
- Prerequisites check: 5 seconds
- PostgreSQL startup: 10-15 seconds
- API startup: 20-30 seconds (no rebuild)
- UI startup: 5-10 seconds (deps cached)
- **Total: ~1-2 minutes**

## Success Criteria

After `integrate.sh` completes:

- ✅ PostgreSQL container running: `docker ps | grep hickory-postgres`
- ✅ API process running: `ps aux | grep control_api`
- ✅ UI process running: `ps aux | grep "npm run dev"`
- ✅ PostgreSQL responding: `nc -z localhost 5432`
- ✅ API responding: `curl http://localhost:8080/health`
- ✅ UI responding: `curl http://localhost:3000`
- ✅ Can access: http://localhost:3000
- ✅ Can login: admin / admin123

## Troubleshooting Integration Script

If `integrate.sh` fails at any phase:

1. Check logs: `tail -f /tmp/hickory-logs/*.log`
2. For phase-specific errors:
   - **Phase 1 (prereqs):** Run `check_system.sh`
   - **Phase 2 (PostgreSQL):** Check `docker ps`, Docker daemon running
   - **Phase 3 (API):** Check `build.log`, ensure Rust installed
   - **Phase 4 (UI):** Check `npm-install.log`, Node.js version
   - **Phase 5 (tests):** Check `e2e-tests.log` for test failures
3. Manual startup:
   - PostgreSQL: `docker run -d --name hickory-postgres --network host -e POSTGRES_DB=hickory -e POSTGRES_PASSWORD=password postgres:15-alpine`
   - API: `cd crates/control_api && cargo build --release && ./target/release/control_api`
   - UI: `cd web/ui && npm install && npm run dev`

## Cleanup

After testing, clean up with:

```bash
# Stop services
bash stop-services.sh

# Or manually:
docker stop hickory-postgres
pkill -f control_api
pkill -f "npm run dev"

# Clean logs
rm -rf /tmp/hickory-logs/
```

## Next Steps

1. Run the integration script:
   ```bash
   bash integrate.sh
   ```

2. Wait for completion and monitor logs:
   ```bash
   tail -f /tmp/hickory-logs/api.log
   tail -f /tmp/hickory-logs/ui.log
   ```

3. Access the application:
   ```
   http://localhost:3000
   Login: admin / admin123
   ```

4. Run tests:
   ```bash
   cd web/ui
   npm run test:e2e
   ```

5. Stop services:
   ```bash
   bash stop-services.sh
   ```

## Summary

✅ **Consolidated from 6+ scripts to 2 main scripts**
✅ **Master script (integrate.sh) handles full orchestration**
✅ **Quick script (run_quick_integration.sh) for development**
✅ **Clear documentation (INTEGRATION.md, INTEGRATION_TROUBLESHOOTING.md)**
✅ **Proper error handling and prerequisite checks**
✅ **Comprehensive logging to /tmp/hickory-logs/**
✅ **Cleanup script (stop-services.sh) for service management**

Ready to run: `bash integrate.sh`
