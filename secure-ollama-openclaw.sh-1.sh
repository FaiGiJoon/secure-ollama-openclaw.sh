#!/bin/bash

# --- CONFIGURATION ---
MY_USER="ollama_admin"
MY_PASSWORD="YourSuperSecurePassword123"
DOMAIN_OR_IP="your_server_ip" 

echo "--- 1. Binding Ollama to Localhost ---"
sudo mkdir -p /etc/systemd/system/ollama.service.d
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
Environment="OLLAMA_ORIGINS=*"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "--- 2. Installing Nginx and Auth Tools ---"
sudo apt update && sudo apt install -y nginx apache2-utils

echo "--- 3. Creating Credentials ---"
echo "$MY_PASSWORD" | htpasswd -bc /etc/nginx/.htpasswd "$MY_USER"

echo "--- 4. Configuring Nginx for OpenClaw Compatibility ---"
cat <<EOF | sudo tee /etc/nginx/sites-available/ollama
server {
    listen 80;
    server_name $DOMAIN_OR_IP;

    # Allow large requests (needed if you upload files/images to OpenClaw)
    client_max_body_size 100M;

    location / {
        # Authentication
        auth_basic "Restricted AI Access";
        auth_basic_user_file /etc/nginx/.htpasswd;

        # CORS Headers for OpenClaw
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;

        # Handle Preflight OPTIONS requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Content-Length' 0;
            add_header 'Content-Type' text/plain;
            return 204;
        }

        # Proxy to Ollama
        proxy_pass http://127.0.0.1:11434;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Streaming settings
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_read_timeout 600s;
    }
}
EOF

echo "--- 5. Enabling Configuration & Restarting ---"
sudo ln -sf /etc/nginx/sites-available/ollama /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo "-------------------------------------------------------"
echo "SETUP COMPLETE"
echo "Access at: http://$DOMAIN_OR_IP"
echo "In OpenClaw settings, set the OLLAMA_HOST to:"
echo "http://$MY_USER:$MY_PASSWORD@$DOMAIN_OR_IP"
echo "-------------------------------------------------------"
