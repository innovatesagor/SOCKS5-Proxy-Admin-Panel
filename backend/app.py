from flask import Flask, request, jsonify
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
import os
import subprocess
import pexpect
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

# JWT Configuration
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "your-secret-key-here")
jwt = JWTManager(app)

# Admin credentials (should be configured via environment variables)
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")

def is_valid_username(username):
    """Validate username (alphanumeric, lowercase, reasonable length)"""
    return username.isalnum() and username.islower() and 3 <= len(username) <= 32

def is_valid_password(password):
    """Validate password (minimum length)"""
    return len(password) >= 8

def is_system_user(username):
    """Check if the username belongs to a system user"""
    system_users = ['root', 'flask_api_user', ADMIN_USERNAME]
    return username in system_users

@app.route("/admin/login", methods=["POST"])
def login():
    username = request.json.get("username", None)
    password = request.json.get("password", None)

    if username != ADMIN_USERNAME or password != ADMIN_PASSWORD:
        return jsonify({"msg": "Bad username or password"}), 401

    access_token = create_access_token(identity=username)
    return jsonify(access_token=access_token)

@app.route("/proxy/users", methods=["POST"])
@jwt_required()
def create_user():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "Username and password are required"}), 400

    if not is_valid_username(username):
        return jsonify({"error": "Invalid username format"}), 400

    if not is_valid_password(password):
        return jsonify({"error": "Password must be at least 8 characters"}), 400

    try:
        # Create user without home directory and with nologin shell
        subprocess.run(['sudo', 'useradd', '-M', '-s', '/usr/sbin/nologin', username], check=True)
        
        # Set user password using pexpect
        child = pexpect.spawn(f'sudo passwd {username}')
        child.expect('Enter new UNIX password:')
        child.sendline(password)
        child.expect('Retype new UNIX password:')
        child.sendline(password)
        child.expect(pexpect.EOF)
        
        return jsonify({"message": f"SOCKS5 user '{username}' created successfully"}), 201
    except subprocess.CalledProcessError as e:
        return jsonify({"error": f"Failed to create user: {str(e)}"}), 500
    except Exception as e:
        return jsonify({"error": f"System error: {str(e)}"}), 500

@app.route("/proxy/users", methods=["GET"])
@jwt_required()
def list_users():
    try:
        # Read /etc/passwd and filter SOCKS5 users
        users = []
        with open('/etc/passwd', 'r') as f:
            for line in f:
                parts = line.strip().split(':')
                if len(parts) >= 7:
                    username, _, uid, _, _, home, shell = parts
                    if (int(uid) >= 1000 and 
                        shell == '/usr/sbin/nologin' and 
                        not is_system_user(username)):
                        users.append({"username": username})
        
        return jsonify({"users": users})
    except Exception as e:
        return jsonify({"error": f"Failed to list users: {str(e)}"}), 500

@app.route("/proxy/users/<username>", methods=["DELETE"])
@jwt_required()
def delete_user(username):
    if not username or is_system_user(username):
        return jsonify({"error": "Invalid or protected username"}), 403

    try:
        subprocess.run(['sudo', 'userdel', '-r', username], check=True)
        return jsonify({"message": f"SOCKS5 user '{username}' deleted successfully"})
    except subprocess.CalledProcessError as e:
        return jsonify({"error": f"Failed to delete user: {str(e)}"}), 500
    except Exception as e:
        return jsonify({"error": f"System error: {str(e)}"}), 500

@app.route("/proxy/status", methods=["GET"])
@jwt_required()
def proxy_status():
    try:
        # Check if service is active
        result = subprocess.run(['sudo', 'systemctl', 'is-active', 'danted'], 
                              capture_output=True, text=True)
        is_active = result.returncode == 0
        status = result.stdout.strip()

        # Get detailed status
        details = subprocess.run(['sudo', 'systemctl', 'status', 'danted'],
                               capture_output=True, text=True).stdout

        return jsonify({
            "status": status,
            "is_active": is_active,
            "details": details
        })
    except Exception as e:
        return jsonify({"error": f"Failed to get proxy status: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5001)
