#!/bin/bash

# --- CONFIGURATION ---
MY_USER="admin"
MY_PASSWORD="YourSecretPassword" # CHANGE THIS BEFORE RUNNING
MY_IP=$(hostname -I | awk '{print $1}')

# Security Check: Prevent execution with default password
if [[ "$MY_PASSWORD" == "YourSecretPassword" ]]; then
    echo "CRITICAL SECURITY ERROR: Default password detected."
    echo "Please edit the MY_PASSWORD variable in this script to a secure value."
    exit 1
fi

echo "--- 1. Locking Ollama & OpenClaw to Localhost ---"
# Force Ollama to only listen internally
sudo mkdir -p /etc/systemd/system/ollama.service.d
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
EOF

# Standard OpenClaw port is 3000
sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "--- 2. Setting up Nginx Password ---"
sudo apt update && sudo apt install -y nginx apache2-utils
# Use printf to avoid trailing newline and -i to read from stdin securely
printf "%s" "$MY_PASSWORD" | sudo htpasswd -ic /etc/nginx/.htpasswd "$MY_USER"

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
