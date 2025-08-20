# SOCKS5 Proxy Admin Panel

A secure web-based administration panel for managing SOCKS5 proxy users and monitoring proxy service status.

---

## VPS & Environment Details
- **Provider:** OVH SAS
- **IP Address:** 15.204.41.229
- **OS:** Ubuntu/Debian (apt)

---

## 1. Prepare & Upload Project (Git)

### On your local machine:
1. Initialize a git repository:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: SOCKS5 Proxy Admin Panel"
   ```
2. Create a remote repository and push your code:
   ```bash
   git remote add origin https://github.com/innovatesagor/SOCKS5-Proxy-Admin-Panel.git
   git push -u origin main
   ```

### On your VPS (15.204.41.229):
1. Install git:
   ```bash
   sudo apt update
   sudo apt install git -y
   ```
2. Clone your repository:
   ```bash
   git clone https://github.com/innovatesagor/SOCKS5-Proxy-Admin-Panel.git /opt/socks5_admin
   cd /opt/socks5_admin
   ```

---

## 2. Backend Setup (Flask API)

1. **Create system user for Flask API:**
   ```bash
   sudo useradd -r -s /usr/sbin/nologin flask_api_user
   ```
2. **Set up Python environment:**
   ```bash
   cd /opt/socks5_admin/backend
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
3. **Configure sudo permissions:**
   ```bash
   sudo cp flask_api_user.sudoers /etc/sudoers.d/flask_api_user
   sudo chmod 440 /etc/sudoers.d/flask_api_user
   ```
4. **Set up systemd service:**
   ```bash
   sudo cp socks5_admin_api.service /etc/systemd/system/
   sudo nano /etc/systemd/system/socks5_admin_api.service
   # Edit environment variables: ADMIN_USERNAME, ADMIN_PASSWORD, JWT_SECRET_KEY
   sudo systemctl enable socks5_admin_api
   sudo systemctl start socks5_admin_api
   ```

---

## 3. Frontend Setup (React)

1. **Build the frontend:**
   ```bash
   cd /opt/socks5_admin/frontend
   npm install
   npm run build
   ```
2. **Deploy static files:**
   ```bash
   sudo mkdir -p /var/www/html/socks5_admin_frontend
   sudo cp -r dist/* /var/www/html/socks5_admin_frontend/
   ```

---

## 4. Nginx Setup

1. **Install Nginx:**
   ```bash
   sudo apt install nginx -y
   ```
2. **Configure Nginx:**
   ```bash
   sudo cp /opt/socks5_admin/frontend/nginx.conf /etc/nginx/sites-available/socks5-admin
   sudo ln -s /etc/nginx/sites-available/socks5-admin /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

---

## 5. Dante SOCKS5 Proxy

1. **Install Dante:**
   ```bash
   sudo apt install dante-server -y
   ```
2. **Configure Dante for PAM authentication:**
   - Edit `/etc/danted.conf` as needed (see Dante docs)
   ```bash
   sudo systemctl enable danted
   sudo systemctl start danted
   ```

---

## 6. Usage

- Access the admin panel: `http://15.204.41.229/`
- Log in with admin credentials (set in systemd service file)
- Manage SOCKS5 users and monitor proxy status

---

## 7. Client Configuration

### macOS
1. System Settings > Network > Wi-Fi/Ethernet > Details > Proxies
2. Configure SOCKS5 proxy:
   - Server: 15.204.41.229
   - Port: 1080
   - Username/password: as created in admin panel

### Android
1. Install a SOCKS5 client app (e.g., SocksDroid)
2. Configure:
   - Server: 15.204.41.229
   - Port: 1080
   - Username/password: as created in admin panel

---

## 8. Security Considerations
- Flask API runs as unprivileged user with limited sudo
- No SOCKS5 user passwords stored by API
- All API endpoints (except login) require JWT
- Frontend uses secure HTTP headers
- Regular system user accounts for SOCKS5 authentication
- Consider HTTPS with Let's Encrypt for production

---

## 9. Development & Troubleshooting

### Backend Development
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
FLASK_ENV=development python app.py
```

### Frontend Development
```bash
cd frontend
npm install
npm run dev
```

### Service Status & Logs
```bash
sudo systemctl status socks5_admin_api
sudo systemctl status danted
sudo systemctl status nginx
sudo journalctl -u socks5_admin_api
sudo journalctl -u danted
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Common Issues
- Ensure proper permissions on sudoers file
- Verify Dante is configured for PAM authentication
- Check Nginx proxy configuration
- Verify JWT secret is properly set
