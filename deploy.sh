#!/bin/bash
# SOCKS5 Proxy Admin Panel Automated Deployment Script
# VPS: OVH SAS, IP: 15.204.41.229, OS: Ubuntu/Debian

set -e
trap 'echo "[ERROR] at line $LINENO: $BASH_COMMAND"' ERR

# --- CONFIG ---
INSTALL_DIR="$(pwd)"
ADMIN_USER="admin"
ADMIN_PASS=$(openssl rand -base64 12)
JWT_SECRET=$(openssl rand -base64 32)

# --- SYSTEM PREP ---
echo "[+] Updating system and installing dependencies..."
sudo apt update || { echo "[ERROR] apt update failed. Check your network and sources."; exit 1; }
sudo apt install -y git python3 python3-venv python3-pip nginx dante-server curl || { echo "[ERROR] apt install failed. Check for held/broken packages."; exit 1; }

# --- NODEJS/NPM INSTALL ---
echo "[+] Installing Node.js and npm using NodeSource..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || { echo "[ERROR] NodeSource setup failed."; exit 1; }
sudo apt install -y nodejs || { echo "[ERROR] Node.js install failed."; exit 1; }
node -v || { echo "[ERROR] Node.js not installed correctly"; exit 1; }
npm -v || { echo "[ERROR] npm not installed correctly"; exit 1; }

# --- BACKEND SETUP ---
echo "[+] Creating flask_api_user system user..."
sudo useradd -r -s /usr/sbin/nologin flask_api_user || echo "[INFO] flask_api_user already exists."

echo "[+] Setting up Python environment..."
cd backend
python3 -m venv venv || { echo "[ERROR] venv creation failed. Check Python version."; exit 1; }
source venv/bin/activate
pip install -r requirements.txt || { echo "[ERROR] pip install failed. Check requirements.txt for typos or missing packages."; exit 1; }

# --- SUDOERS ---
echo "[+] Configuring sudoers..."
sudo cp flask_api_user.sudoers /etc/sudoers.d/flask_api_user || { echo "[ERROR] sudoers copy failed. Check file permissions."; exit 1; }
sudo chmod 440 /etc/sudoers.d/flask_api_user

# --- SYSTEMD SERVICE ---
echo "[+] Setting up systemd service..."
sudo cp socks5_admin_api.service /etc/systemd/system/ || { echo "[ERROR] systemd service copy failed. Check file permissions."; exit 1; }
sudo sed -i "s|Environment=\"ADMIN_USERNAME=.*\"|Environment=\"ADMIN_USERNAME=$ADMIN_USER\"|g" /etc/systemd/system/socks5_admin_api.service
sudo sed -i "s|Environment=\"ADMIN_PASSWORD=.*\"|Environment=\"ADMIN_PASSWORD=$ADMIN_PASS\"|g" /etc/systemd/system/socks5_admin_api.service
sudo sed -i "s|Environment=\"JWT_SECRET_KEY=.*\"|Environment=\"JWT_SECRET_KEY=$JWT_SECRET\"|g" /etc/systemd/system/socks5_admin_api.service
sudo systemctl daemon-reload
sudo systemctl enable socks5_admin_api
sudo systemctl restart socks5_admin_api || { echo "[ERROR] Flask API service failed to start. Check logs below:"; sudo journalctl -u socks5_admin_api --no-pager -n 30; exit 1; }

# --- FRONTEND SETUP ---
echo "[+] Building frontend..."
cd "$INSTALL_DIR/frontend"
# Clean old node_modules, lock file, and cache
echo "[INFO] Removing old node_modules, package-lock.json, and .vite cache..."
rm -rf node_modules package-lock.json .vite
# Install all required frontend dependencies
npm install || { echo "[ERROR] npm install failed. Check package.json for errors."; exit 1; }
npm install react-router-dom axios || { echo "[ERROR] npm install react-router-dom axios failed. Check your internet connection and package.json."; exit 1; }
# If you add more dependencies in your code, add them here
npm run build || { echo "[ERROR] npm run build failed. Check for missing imports or typos in your React code."; exit 1; }

# --- Deploy static files ---
echo "[+] Deploying frontend static files..."
sudo mkdir -p /var/www/html/socks5_admin_frontend
sudo cp -r dist/* /var/www/html/socks5_admin_frontend/ || { echo "[ERROR] Frontend deploy failed. Check dist/ folder exists."; exit 1; }

# --- NGINX SETUP ---
echo "[+] Configuring Nginx..."
sudo cp "$INSTALL_DIR/frontend/nginx.conf" /etc/nginx/sites-available/socks5-admin || { echo "[ERROR] Nginx config copy failed. Check file permissions."; exit 1; }
sudo ln -sf /etc/nginx/sites-available/socks5-admin /etc/nginx/sites-enabled/socks5-admin
sudo nginx -t || { echo "[ERROR] Nginx config test failed. Check error log below:"; sudo tail -n 30 /var/log/nginx/error.log; exit 1; }
sudo systemctl reload nginx

# --- DANTE SETUP ---
echo "[+] Ensuring Dante SOCKS5 is enabled..."
sudo systemctl enable danted
sudo systemctl restart danted || { echo "[ERROR] Dante service failed to start. Check logs below:"; sudo journalctl -u danted --no-pager -n 30; exit 1; }

# --- OUTPUT ---
echo "\n[DEPLOYMENT COMPLETE]"
echo "Admin Panel URL: http://15.204.41.229/"
echo "Login Username: $ADMIN_USER"
echo "Login Password: $ADMIN_PASS"
echo "(You can change these in /etc/systemd/system/socks5_admin_api.service)"
echo "If you see any error above, check the log output and update your frontend/backend code or package.json as needed."
