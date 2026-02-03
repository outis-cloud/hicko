# Integration Scripts - Consolidation Complete

## Summary

✅ **Consolidated 6+ integration scripts into 2 essential, well-documented scripts**

## Scripts Kept (2 Total)

### 1. `/workspaces/hicko/integrate.sh` (263 lines)
**Master Integration Script - Full Production Setup**

What it does:
- ✓ Verifies all prerequisites (Docker, Node.js, Rust)
- ✓ Starts PostgreSQL 15 database in Docker
- ✓ Builds Rust API in release mode
- ✓ Installs UI dependencies with npm
- ✓ Starts UI dev server on port 3000
- ✓ Optionally runs Playwright E2E tests
- ✓ Reports final status of all services
- ✓ Keeps services running (Ctrl+C to stop)

When to use:
- Full system integration testing
- Before pushing to production
- Verifying all components work together
- First-time setup

Run with:
```bash
bash integrate.sh
```

### 2. `/workspaces/hicko/run_quick_integration.sh` (212 lines)
**Quick Development Script - Rapid Iteration**

What it does:
- ✓ Graceful error handling (doesn't fail on missing services)
- ✓ Checks prerequisites without exiting
- ✓ Starts services that are available
- ✓ Continues even if one service fails
- ✓ Shows what's running and what's not

When to use:
- Rapid development and testing
- When one service is already running
- Debugging individual components
- Testing without full setup

Run with:
```bash
bash run_quick_integration.sh
```

## Supporting Scripts (3 Total)

### 3. `/workspaces/hicko/stop-services.sh` (35 lines)
**Service Manager - Graceful Shutdown**

Stops:
- Rust API process
- Node.js dev server
- PostgreSQL Docker container
- Cleanup of stray processes

### 4. `/workspaces/hicko/check_system.sh` (70 lines)
**System Checker - Prerequisite Verification**

Verifies:
- Docker installation and running status
- Node.js installation
- Rust toolchain
- Project files exist

### 5. `/workspaces/hicko/verify_production_readiness.sh`
**Production Validator - Compliance Checks**

Already existed; used by `integrate.sh`

## Scripts Removed (For Cleanup)

The following can be safely deleted as they're replaced by `integrate.sh`:

- `run_complete_integration.sh` - Verbose, replaced by integrate.sh
- `run_full_integration.sh` - Duplicate, replaced by integrate.sh
- `start_integration_test.sh` - Redundant helper
- `start_api.sh` - Individual service script (use integrate.sh instead)

## Documentation Created

1. **INTEGRATION.md** - How to use scripts + troubleshooting quick ref
2. **INTEGRATION_SETUP_COMPLETE.md** - This file
3. **INTEGRATION_TROUBLESHOOTING.md** - Detailed problem solving

## Directory Structure

```
/workspaces/hicko/
├── integrate.sh                          ← Master script (USE THIS)
├── run_quick_integration.sh             ← Quick mode (use for dev)
├── stop-services.sh                     ← Service cleanup
├── check_system.sh                      ← Prerequisites check
├── verify_production_readiness.sh       ← Production checker
├── check_backend_connectivity.sh        ← API validator
│
├── INTEGRATION.md                       ← Usage guide
├── INTEGRATION_SETUP_COMPLETE.md        ← This file
├── INTEGRATION_TROUBLESHOOTING.md       ← Problem solving
│
├── crates/control_api/                  ← Rust backend
├── web/ui/                              ← React frontend
└── tests/                               ← Test suite
```

## Quick Reference

### Start Everything
```bash
bash integrate.sh
```

### Start (Graceful, Skip Missing Services)
```bash
bash run_quick_integration.sh
```

### Stop Everything
```bash
bash stop-services.sh
```

### Check System Ready
```bash
bash check_system.sh
```

### Access Application
```
http://localhost:3000
Username: admin
Password: admin123
```

### View Logs
```bash
tail -f /tmp/hickory-logs/api.log
tail -f /tmp/hickory-logs/ui.log
tail -f /tmp/hickory-logs/postgres.log
```

### Manual Service Control

Start PostgreSQL:
```bash
docker run -d --name hickory-postgres --network host \
  -e POSTGRES_DB=hickory -e POSTGRES_PASSWORD=password \
  postgres:15-alpine
```

Start API:
```bash
cd /workspaces/hicko/crates/control_api
export DATABASE_URL="postgres://postgres:password@localhost:5432/hickory"
export JWT_SECRET="dev-secret-key"
cargo build --release
./target/release/control_api
```

Start UI:
```bash
cd /workspaces/hicko/web/ui
npm install
npm run dev
```

## Environment Variables

Automatically set by `integrate.sh`:

```bash
DATABASE_URL=postgres://postgres:password@localhost:5432/hickory
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
JWT_SECRET=dev-secret-key-change-in-production
RUST_LOG=info
```

## Execution Timeline

**First Run:**
- Prerequisites check: 5 sec
- PostgreSQL start: 15 sec
- API build: 3-5 min
- npm install: 1-2 min
- UI start: 10 sec
- **Total: 10-15 minutes**

**Subsequent Runs:**
- Prerequisites check: 5 sec
- PostgreSQL start: 15 sec
- API start: 30 sec
- UI start: 5 sec
- **Total: 1-2 minutes**

## Verification

After `integrate.sh` completes:

Check API:
```bash
curl http://localhost:8080/health
# Should return: {"status":"ok"}
```

Check UI:
```bash
curl http://localhost:3000
# Should return HTML
```

Check PostgreSQL:
```bash
nc -z localhost 5432 && echo "PostgreSQL OK"
```

Check Processes:
```bash
ps aux | grep -E "(control_api|npm|postgres)" | grep -v grep
```

## Common Issues & Solutions

**Docker not running:**
```bash
sudo systemctl start docker  # Linux
# or open Docker Desktop app (Mac/Windows)
```

**Port 3000 in use:**
```bash
lsof -i :3000 && kill -9 <PID>
```

**Port 8080 in use:**
```bash
pkill -f control_api
```

**npm install fails:**
```bash
cd web/ui && npm cache clean --force && npm install
```

**cargo build fails:**
```bash
cd crates/control_api && cargo clean && cargo build --release
```

## Next Actions

1. **Ready to test:** `bash integrate.sh`
2. **Check system first:** `bash check_system.sh`
3. **View progress:** `tail -f /tmp/hickory-logs/api.log`
4. **Access app:** http://localhost:3000 (admin/admin123)
5. **Stop services:** `bash stop-services.sh`

---

**Status:** ✅ Integration scripts consolidated and ready for use
**Last Updated:** 2026-02-03
