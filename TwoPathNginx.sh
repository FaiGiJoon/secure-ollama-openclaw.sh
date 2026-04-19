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

# Standard OpenClaw port is 3000
sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "--- 2. Setting up Nginx Password ---"
sudo apt update && sudo apt install -y nginx apache2-utils
echo "$MY_PASSWORD" | htpasswd -bc /etc/nginx/.htpasswd "$MY_USER"

echo "--- 3. Configuring Unified Reverse Proxy ---"
# Use the standardized template from proxies/nginx/
sudo cp proxies/nginx/ollama-openclaw.conf /etc/nginx/sites-available/ai-suite
# Update placeholder domain to current IP or use _
sudo sed -i "s/yourdomain.com/_/" /etc/nginx/sites-available/ai-suite

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
