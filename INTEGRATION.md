# Integration Scripts

This directory contains two essential integration scripts for Hickory DNS Manager:

## Quick Start

### Run Full Integration
```bash
bash integrate.sh
```
This is the **recommended** way to start everything. It:
- Starts PostgreSQL 15 in Docker
- Builds the Rust API
- Starts the UI dev server
- Optionally runs E2E tests
- Shows status of all services

**Time to completion:** 5-15 minutes (first run) / 1-2 minutes (subsequent runs)

### Run Quick Test (Dev Mode)
```bash
bash run_quick_integration.sh
```
Faster alternative that:
- Checks prerequisites without exiting
- Starts services with graceful error handling
- Continues even if some services fail
- Useful for rapid iteration

**Time to completion:** 2-5 minutes

### Stop All Services
```bash
bash stop-services.sh
```

## System Requirements

Before running integration, ensure you have:
- ✓ **Docker** - for PostgreSQL
  - Check: `docker ps`
  - Fix: Install Docker or start Docker daemon
  
- ✓ **Node.js 16+** - for UI
  - Check: `node --version`
  - Fix: Install from nodejs.org
  
- ✓ **Rust** - for API
  - Check: `cargo --version`
  - Fix: Install from rustup.rs

## What Gets Started

### PostgreSQL (Port 5432)
- Database: `hickory`
- User: `postgres`
- Password: `password`
- Status: Check with `docker ps | grep hickory-postgres`

### API (Port 8080)
- Location: `/crates/control_api`
- Health: `curl http://localhost:8080/health`
- Logs: `tail -f /tmp/hickory-logs/api.log`

### UI (Port 3000)
- Location: `/web/ui`
- Access: http://localhost:3000
- Logs: `tail -f /tmp/hickory-logs/ui.log`
- Credentials: `admin` / `admin123`

## Accessing the Application

Once integration completes:

1. Open http://localhost:3000 in your browser
2. Login with:
   - Username: `admin`
   - Password: `admin123`
3. Use the DNS Manager UI

## Logs

All service logs are saved to `/tmp/hickory-logs/`:

```bash
# View all logs
ls -lh /tmp/hickory-logs/

# Monitor API
tail -f /tmp/hickory-logs/api.log

# Monitor UI
tail -f /tmp/hickory-logs/ui.log

# Monitor PostgreSQL
tail -f /tmp/hickory-logs/postgres.log

# View build output
tail -f /tmp/hickory-logs/build.log
```

## Troubleshooting

### "Docker not available"
```bash
# Check if Docker is running
docker ps

# Start Docker if needed
sudo systemctl start docker  # Linux
# or open Docker Desktop app (Mac/Windows)
```

### "Port 3000 already in use"
```bash
# Kill the process on port 3000
lsof -i :3000
kill -9 <PID>
```

### "Port 8080 already in use"
```bash
# Kill the API process
pkill -f control_api
```

### "PostgreSQL failed to start"
```bash
# Check Docker logs
docker logs hickory-postgres

# Try removing old container
docker rm -f hickory-postgres
```

### "npm install failed"
```bash
cd /workspaces/hicko/web/ui
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### "cargo build failed"
```bash
cd /workspaces/hicko/crates/control_api
cargo clean
cargo build --release
```

## Running Tests Only

After services are running, run E2E tests separately:

```bash
cd /workspaces/hicko/web/ui
npm run test:e2e
```

## Manual Service Startup

If you prefer to start services manually:

### PostgreSQL
```bash
docker run -d \
  --name hickory-postgres \
  --network host \
  -e POSTGRES_DB=hickory \
  -e POSTGRES_PASSWORD=password \
  postgres:15-alpine
```

### API
```bash
cd /workspaces/hicko/crates/control_api
export DATABASE_URL="postgres://postgres:password@localhost:5432/hickory"
export JWT_SECRET="dev-secret-key"
cargo run --release
```

### UI
```bash
cd /workspaces/hicko/web/ui
npm install
npm run dev
```

## Environment Variables

The integration script sets these automatically:

```bash
DATABASE_URL=postgres://postgres:password@localhost:5432/hickory
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
JWT_SECRET=dev-secret-key-change-in-production
RUST_LOG=info
```

## Architecture

```
integrate.sh (Master)
├── PostgreSQL 15 (Docker)
├── Rust API (Actix-web)
│   └── /crates/control_api
├── React UI (Vite dev server)
│   └── /web/ui
└── E2E Tests (Playwright)
    └── /web/ui/tests
```

## Documentation

For more information, see:
- [README.md](../README.md) - Project overview
- [DEVELOPER_QUICK_GUIDE.md](../DEVELOPER_QUICK_GUIDE.md) - Development guide
- [INTEGRATION_TROUBLESHOOTING.md](../INTEGRATION_TROUBLESHOOTING.md) - Detailed troubleshooting
- [/web/ui/SETUP.md](../web/ui/SETUP.md) - UI setup guide
