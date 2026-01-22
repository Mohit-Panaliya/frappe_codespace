#!/usr/bin/env bash
set -e

BENCH_DIR="/workspaces/frappe_codespace/frappe-bench"

echo "🚀 Initializing Frappe Framework v16 Codespace..."

# Skip if bench already exists
if [[ -d "$BENCH_DIR/apps/frappe" ]]; then
    echo "✅ Bench already exists, skipping initialization"
    exit 0
fi

# Remove repo git history (Codespace best practice)
rm -rf /workspaces/frappe_codespace/.git || true

# -----------------------------
# Node.js (nvm + Node 24)
# -----------------------------
export NVM_DIR="$HOME/.nvm"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
else
    echo "❌ nvm not found"
    exit 1
fi

nvm install 24
nvm alias default 24
nvm use 24

echo 'nvm use 24' >> ~/.bashrc

node -v
npm install -g yarn

# -----------------------------
# Python (uv)
# -----------------------------
if ! command -v uv &> /dev/null; then
    echo "❌ uv not found"
    exit 1
fi

# Recommended Python for Frappe 16
uv python install 3.14 --default

# -----------------------------
# Bench CLI
# -----------------------------
if ! command -v bench &> /dev/null; then
    uv tool install frappe-bench
fi

bench --version

# -----------------------------
# Initialize Bench (Frappe v16)
# -----------------------------
cd /workspaces/frappe_codespace

bench init frappe-bench \
    --frappe-branch version-16 \
    --ignore-exist \
    --skip-redis-config-generation

cd frappe-bench

# -----------------------------
# Container-based Services (FIXED FOR v16)
# -----------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis-cache:6379
bench set-redis-queue-host redis://redis-queue:6379
bench set-redis-socketio-host redis://redis-socketio:6379

# Remove redis services from Procfile (Docker-managed)
sed -i '/redis/d' Procfile

# -----------------------------
# Create Development Site
# -----------------------------
# bench new-site dev.localhost \
#     --mariadb-root-password 123 \
#     --admin-password admin \
#     --no-mariadb-socket

# bench --site dev.localhost set-config developer_mode 1
# bench --site dev.localhost clear-cache
# bench use dev.localhost

# -----------------------------
# Create Development Site (Frappe 16)
# -----------------------------
bench new-site dev.localhost \
    --mariadb-root-password 123 \
    --admin-password admin \
    --mariadb-user-host-login-scope='%'

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost


echo "✅ Frappe 16 setup complete!"
echo "➡️  Run: bench start"
