#!/bin/bash
# SOCKS5 Proxy Admin Panel Automated Deployment Script
# VPS: OVH SAS, IP: 15.204.41.229, OS: Ubuntu/Debian

set -e

# --- CONFIG ---
INSTALL_DIR="$(pwd)"
ADMIN_USER="admin"
ADMIN_PASS=$(openssl rand -base64 12)
JWT_SECRET=$(openssl rand -base64 32)

# --- SYSTEM PREP ---
echo "[+] Updating system and installing dependencies..."
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip nginx dante-server npm

# --- BACKEND SETUP ---
echo "[+] Creating flask_api_user system user..."
sudo useradd -r -s /usr/sbin/nologin flask_api_user || true

echo "[+] Setting up Python environment..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "[+] Configuring sudoers..."
sudo cp flask_api_user.sudoers /etc/sudoers.d/flask_api_user
sudo chmod 440 /etc/sudoers.d/flask_api_user

echo "[+] Setting up systemd service..."
sudo cp socks5_admin_api.service /etc/systemd/system/
sudo sed -i "s|Environment=\"ADMIN_USERNAME=.*\"|Environment=\"ADMIN_USERNAME=$ADMIN_USER\"|g" /etc/systemd/system/socks5_admin_api.service
sudo sed -i "s|Environment=\"ADMIN_PASSWORD=.*\"|Environment=\"ADMIN_PASSWORD=$ADMIN_PASS\"|g" /etc/systemd/system/socks5_admin_api.service
sudo sed -i "s|Environment=\"JWT_SECRET_KEY=.*\"|Environment=\"JWT_SECRET_KEY=$JWT_SECRET\"|g" /etc/systemd/system/socks5_admin_api.service
sudo systemctl daemon-reload
sudo systemctl enable socks5_admin_api
sudo systemctl restart socks5_admin_api

# --- FRONTEND SETUP ---
echo "[+] Building frontend..."
cd "$INSTALL_DIR/frontend"
npm install
npm run build

echo "[+] Deploying frontend static files..."
sudo mkdir -p /var/www/html/socks5_admin_frontend
sudo cp -r dist/* /var/www/html/socks5_admin_frontend/

# --- NGINX SETUP ---
echo "[+] Configuring Nginx..."
sudo cp "$INSTALL_DIR/frontend/nginx.conf" /etc/nginx/sites-available/socks5-admin
sudo ln -sf /etc/nginx/sites-available/socks5-admin /etc/nginx/sites-enabled/socks5-admin
sudo nginx -t
sudo systemctl reload nginx

# --- DANTE SETUP ---
echo "[+] Ensuring Dante SOCKS5 is enabled..."
sudo systemctl enable danted
sudo systemctl restart danted

# --- OUTPUT ---
echo "\n[DEPLOYMENT COMPLETE]"
echo "Admin Panel URL: http://15.204.41.229/"
echo "Login Username: $ADMIN_USER"
echo "Login Password: $ADMIN_PASS"
echo "(You can change these in /etc/systemd/system/socks5_admin_api.service)"
