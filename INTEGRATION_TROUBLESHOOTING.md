# Integration Script Troubleshooting Guide

## Quick Start

### Simplest Option (Recommended First)
Run the simplified integration script that's more forgiving:
```bash
bash /workspaces/hicko/run_quick_integration.sh
```

This script:
- ✓ Starts PostgreSQL if Docker is available
- ✓ Builds and runs the API if Rust is available
- ✓ Starts the UI dev server if Node.js is available
- ✓ Continues even if some services fail
- ✓ Shows what's running and what's not
- ✓ Keeps services alive while script runs

### Full Integration Test (With Tests)
```bash
bash /workspaces/hicko/run_complete_integration.sh
```

This runs all 7 phases including E2E tests.

## Common Issues & Solutions

### Issue 1: "Docker command not found"
**Problem:** Docker is not installed
**Solution:**
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
# Or use your package manager: apt install docker.io (Ubuntu)
```

### Issue 2: "Cannot connect to Docker daemon"
**Problem:** Docker is installed but not running
**Solution:**
```bash
# Start Docker
sudo systemctl start docker

# Or on Mac/Windows, start Docker Desktop app
```

### Issue 3: "npm command not found"
**Problem:** Node.js is not installed
**Solution:**
```bash
# Install Node.js
sudo apt update
sudo apt install nodejs npm  # Ubuntu
brew install node            # macOS
```

### Issue 4: "cargo command not found"
**Problem:** Rust is not installed
**Solution:**
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### Issue 5: "Port 3000 already in use"
**Problem:** Another process is running on port 3000
**Solution:**
```bash
# Kill the process on port 3000
lsof -i :3000
kill -9 <PID>

# Or use a different port
cd /workspaces/hicko/web/ui
PORT=3001 npm run dev
```

### Issue 6: "Port 8080 already in use"
**Problem:** Another API is running on port 8080
**Solution:**
```bash
# Stop the existing API
pkill -f control_api

# Or find and kill it manually
lsof -i :8080
kill -9 <PID>
```

### Issue 7: "npm install fails"
**Problem:** Dependency installation failing
**Solution:**
```bash
cd /workspaces/hicko/web/ui
# Clear cache and retry
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### Issue 8: "cargo build fails"
**Problem:** Rust build failing
**Solution:**
```bash
cd /workspaces/hicko/crates/control_api
# Update Rust
rustup update

# Try fresh build
cargo clean
cargo build --release
```

## Checking System Status

### Before running integration test:
```bash
# Run diagnostics
bash /workspaces/hicko/check_system.sh
```

This checks:
- ✓ Docker availability and status
- ✓ Node.js installation
- ✓ Rust toolchain
- ✓ Required project files

### After starting services:
```bash
# Check API
curl http://localhost:8080/health

# Check UI
curl http://localhost:3000

# Check PostgreSQL
nc -z localhost 5432 && echo "PostgreSQL running" || echo "PostgreSQL not running"
```

## Monitoring Services

### View logs in real-time:
```bash
# API logs
tail -f /tmp/hickory-logs/api.log

# UI logs
tail -f /tmp/hickory-logs/ui.log

# PostgreSQL logs
tail -f /tmp/hickory-logs/postgres.log

# Build logs
tail -f /tmp/hickory-logs/build.log
```

### List all running services:
```bash
ps aux | grep -E "(control_api|node|postgres)" | grep -v grep
```

### Stop services manually:
```bash
# Stop API
pkill -f control_api

# Stop UI dev server
pkill -f "node.*dev"

# Stop PostgreSQL
docker stop hickory-postgres
```

## Manual Service Startup

If you prefer to start services manually:

### Start PostgreSQL:
```bash
docker run -d \
  --name hickory-postgres \
  --network host \
  -e POSTGRES_DB=hickory \
  -e POSTGRES_PASSWORD=password \
  postgres:15-alpine
```

### Build and start API:
```bash
cd /workspaces/hicko/crates/control_api
export DATABASE_URL="postgres://postgres:password@localhost:5432/hickory"
export JWT_SECRET="dev-secret-key"
cargo build --release
./target/release/control_api
```

### Start UI:
```bash
cd /workspaces/hicko/web/ui
npm install  # if not already done
npm run dev
```

## Accessing the Application

Once all services are running:

1. **Open UI:** http://localhost:3000
2. **Login:**
   - Username: `admin`
   - Password: `admin123`

## Expected Behavior

### First Run (5-15 minutes):
- PostgreSQL: ~10 seconds to start
- API: ~3-5 minutes to build
- UI: ~2-3 minutes for npm install

### Subsequent Runs (1-2 minutes):
- PostgreSQL: ~10 seconds
- API: ~30 seconds to start
- UI: ~10 seconds to start

## E2E Test Execution

After services are running, run tests in another terminal:
```bash
cd /workspaces/hicko/web/ui
npm run test:e2e
```

This will run 40+ test scenarios including:
- ✓ Authentication (login/logout)
- ✓ Dashboard pages
- ✓ CRUD operations
- ✓ Filtering and searching
- ✓ Dark mode toggle
- ✓ Error handling

## Support Information

### File Locations:
- **Project root:** `/workspaces/hicko/`
- **API:** `/workspaces/hicko/crates/control_api/`
- **UI:** `/workspaces/hicko/web/ui/`
- **Tests:** `/workspaces/hicko/web/ui/tests/`
- **Logs:** `/tmp/hickory-logs/`
- **Docs:** `/workspaces/hicko/*.md`

### Key Documentation:
- **README:** `/workspaces/hicko/README.md`
- **API Guide:** `/workspaces/hicko/crates/control_api/README.md`
- **UI Guide:** `/workspaces/hicko/web/ui/SETUP.md`
- **Developer Quick Start:** `/workspaces/hicko/DEVELOPER_QUICK_GUIDE.md`

### Environment Variables:
```
DATABASE_URL=postgres://postgres:password@localhost:5432/hickory
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
JWT_SECRET=dev-secret-key-change-in-production
RUST_LOG=info
```

## Still Having Issues?

1. **Check system prerequisites:**
   ```bash
   bash /workspaces/hicko/check_system.sh
   ```

2. **Review logs:**
   ```bash
   tail -f /tmp/hickory-logs/*.log
   ```

3. **Try simplified script:**
   ```bash
   bash /workspaces/hicko/run_quick_integration.sh
   ```

4. **Start services manually** (see section above)

5. **Check for port conflicts:**
   ```bash
   netstat -tulpn | grep -E "(3000|8080|5432)"
   ```

