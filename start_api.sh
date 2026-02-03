#!/bin/bash
set -e

export DATABASE_URL="host=127.0.0.1 user=postgres password=password dbname=hickory"
export ADMIN_USERNAME="admin"
export ADMIN_PASSWORD="admin123"
export JWT_SECRET="replace_with_a_super_secret"

echo "=== Building and starting Control API ==="
cd /workspaces/hicko
cargo build -p control_api --release 2>&1 | tail -20

echo "=== Starting Control API on port 8080 ==="
./target/release/control_api
