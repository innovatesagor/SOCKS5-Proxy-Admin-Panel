# SOCKS5 Proxy Admin Panel

A secure web-based administration panel for managing SOCKS5 proxy users and monitoring proxy service status.

---

## VPS & Environment Details
- **Provider:** OVH SAS
- **IP Address:** 15.204.41.229
- **OS:** Ubuntu/Debian (apt)

---

## 1. Automated VPS Deployment (Recommended)

### On your VPS (15.204.41.229):

1. **Install git (if not already installed):**
   ```bash
   sudo apt update
   sudo apt install git -y
   ```
2. **Clone your repository:**
   ```bash
   git clone https://github.com/innovatesagor/SOCKS5-Proxy-Admin-Panel.git /opt/socks5_admin
   cd /opt/socks5_admin
   ```
3. **Run the automated deployment script:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```
   This script will:
   - Install all required system packages
   - Set up backend (Flask API, system user, sudoers, systemd)
   - Build and deploy the frontend
   - Configure Nginx
   - Enable and start Dante SOCKS5
   - Generate and display admin credentials and panel URL

---

## 2. Access Admin Panel & Credentials

- After deployment, the script will print:
  - Admin Panel URL: `http://15.204.41.229/`
  - Login Username: `admin`
  - Login Password: (auto-generated, shown in terminal)
- You can change credentials in `/etc/systemd/system/socks5_admin_api.service` and restart the service if needed.

---

## 3. Client Configuration

### macOS
1. System Settings > Network > Wi-Fi/Ethernet > Details > Proxies
2. Configure SOCKS5 proxy:
   - Server: 15.204.41.229
   - Port: 1080
   - Username/password: as shown after deployment

### Android
1. Install a SOCKS5 client app (e.g., SocksDroid)
2. Configure:
   - Server: 15.204.41.229
   - Port: 1080
   - Username/password: as shown after deployment

---

## 4. Security Considerations
- Flask API runs as unprivileged user with limited sudo
- No SOCKS5 user passwords stored by API
- All API endpoints (except login) require JWT
- Frontend uses secure HTTP headers
- Regular system user accounts for SOCKS5 authentication
- Consider HTTPS with Let's Encrypt for production

---

## 5. Development & Troubleshooting

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
