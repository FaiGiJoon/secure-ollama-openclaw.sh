#!/bin/bash

# --- CONFIGURATION ---
MY_USER="admin"
MY_PASSWORD="YourSecretPassword"
MY_IP=$(hostname -I | awk '{print $1}')

echo "--- 1. Locking Ollama & OpenClaw to Localhost ---"
# Force Ollama to only listen internally
sudo mkdir -p /etc/systemd/system/ollama.service.d
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
Environment="OLLAMA_ORIGINS=*"
EOF

# IMPORTANT: For OpenClaw, ensure you start it bound to 127.0.0.1
# If using Docker for OpenClaw, run it with: -p 127.0.0.1:3000:3000
# Standard OpenClaw port is 3000

sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "--- 2. Setting up Nginx Password ---"
sudo apt update && sudo apt install -y nginx apache2-utils
echo "$MY_PASSWORD" | htpasswd -bc /etc/nginx/.htpasswd "$MY_USER"

echo "--- 3. Configuring Unified Reverse Proxy ---"
cat <<EOF | sudo tee /etc/nginx/sites-available/ai-suite
server {
    listen 80;
    server_name _;

    # Global Security Settings
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    client_max_body_size 100M;

    # ROUTE 1: The OpenClaw Dashboard (Port 3000)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # ROUTE 2: The Ollama API (Port 11434)
    location /ollama/ {
        proxy_pass http://127.0.0.1:11434/;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_read_timeout 600s;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS fix for streaming
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    }
}
EOF

echo "--- 4. Activation ---"
sudo ln -sf /etc/nginx/sites-available/ai-suite /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo "-------------------------------------------------------"
echo "COMPLETE! Both services are now behind one password."
echo "Access the OpenClaw Dashboard at: http://$MY_IP"
echo "Access Ollama API at: http://$MY_IP/ollama/"
echo "Username: $MY_USER"
echo "Password: $MY_PASSWORD"
echo "-------------------------------------------------------"
