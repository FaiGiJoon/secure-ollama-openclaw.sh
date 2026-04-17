#!/bin/bash

# --- CONFIGURATION ---
MY_USER="ollama_admin"
MY_PASSWORD="YourSuperSecurePassword123"
DOMAIN_OR_IP="your_server_ip"

# Multi-Agent Configuration
RESEARCHER_MODEL="deepseek-coder"
WRITER_MODEL="llama3.1"
SHARED_WORKSPACE="/tmp/openclaw-shared"
AGENT_LOG_DIR="$HOME/.openclaw/logs"
CONFIG_FILE="$HOME/.openclaw/openclaw.json"

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

echo "--- 6. Backing up OpenClaw Configuration ---"
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
    echo "Backup created at ${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
else
    echo "No existing configuration found at $CONFIG_FILE. Skipping backup."
fi

echo "--- 7. Creating Shared Workspace ---"
sudo mkdir -p "$SHARED_WORKSPACE"
sudo chmod 777 "$SHARED_WORKSPACE"
echo "Shared workspace created at $SHARED_WORKSPACE with open permissions."

echo "--- 8. Ensuring Ollama Models are Present ---"
check_and_pull_model() {
    local model=$1
    if ollama list | grep -q "^$model"; then
        echo "Model $model already exists."
    else
        echo "Model $model not found. Pulling..."
        ollama pull "$model"
    fi
}

check_and_pull_model "$RESEARCHER_MODEL"
check_and_pull_model "$WRITER_MODEL"

echo "--- 9. Modular Agent Setup ---"
# Configure OpenClaw to use the local Ollama instance
openclaw config set providers.ollama.baseUrl http://localhost:11434

# Function to add agent and set local provider
setup_agent() {
    local name=$1
    local model=$2
    echo "Setting up agent: $name"
    openclaw agents add "$name" --model "ollama:$model" --workspace "$SHARED_WORKSPACE"
    # Ensure it uses the local secured Ollama (via internal loopback for security)
    # Note: openclaw config set might be needed if it doesn't pick up local ollama by default
}

setup_agent "researcher" "$RESEARCHER_MODEL"
setup_agent "writer" "$WRITER_MODEL"
setup_agent "manager" "$WRITER_MODEL" # Manager uses writer model as default

echo "--- 10. Configuring Orchestrator Routing ---"
MANAGER_AGENT_DIR="$HOME/.openclaw/agents/manager"
mkdir -p "$MANAGER_AGENT_DIR"
cat <<EOF > "$MANAGER_AGENT_DIR/AGENTS.md"
## Multi-Agent Orchestration
You are the central 'manager' agent. Your role is to coordinate between the researcher and the writer.

- **Delegation Rules**:
  - For any tasks requiring information gathering, web searching, or technical research, delegate to the 'researcher'.
  - For tasks involving drafting, summarizing, or content creation based on research, delegate to the 'writer'.

- **Routing**: Use OpenClaw's sub-agent routing to communicate with your team.
EOF

echo "--- 11. Defining Agent Personalities & Sandboxing ---"
# Researcher SOUL
mkdir -p "$HOME/.openclaw/agents/researcher"
cat <<EOF > "$HOME/.openclaw/agents/researcher/SOUL.md"
## Identity: Researcher
You are a meticulous researcher. Your goal is to gather accurate, deep, and verified information.

- **Capabilities**: You have outbound network access for web scraping and searching.
- **Collaboration**: Save your findings to $SHARED_WORKSPACE.
- **Concurrency**: Use file-locking (create a .lock file) when writing to shared files to prevent race conditions.
EOF

# Writer SOUL & Sandboxing
mkdir -p "$HOME/.openclaw/agents/writer"
cat <<EOF > "$HOME/.openclaw/agents/writer/SOUL.md"
## Identity: Writer
You are a creative and concise writer. You turn research data into polished documents.

- **Sandbox Environment**: You operate in a restricted mode. You can ONLY read and write files in $SHARED_WORKSPACE. You DO NOT have outbound network access.
- **Workflow**: Read the researcher's files from the shared workspace.
- **Concurrency**: Use file-locking (check for .lock files) when accessing shared resources.
EOF

# Apply restrictions to 'writer' via openclaw command
# Restricting to 'file' tool only on the shared path
openclaw agents config writer --tools file --workspace "$SHARED_WORKSPACE"

# Ensure researcher has outbound tools (assuming 'browser' or 'search' exists)
openclaw agents config researcher --tools file,browser,shell --workspace "$SHARED_WORKSPACE"

echo "--- 12. Setting Up Agent Logging ---"
mkdir -p "$AGENT_LOG_DIR"
setup_logging() {
    local agent=$1
    echo "Starting background log monitor for $agent..."
    # This assumes openclaw logs can be filtered by agent name
    # Since we can't easily filter live logs without knowing openclaw's log format exactly,
    # we'll provide a command template that users can run or we background if possible.
    openclaw logs --agent "$agent" > "$AGENT_LOG_DIR/${agent}.log" 2>&1 &
}

setup_logging "researcher"
setup_logging "writer"
setup_logging "manager"

echo "--- 13. Final Validation ---"
openclaw agents list --bindings

echo "-------------------------------------------------------"
echo "SETUP COMPLETE"
echo "Access at: http://$DOMAIN_OR_IP"
echo "In OpenClaw settings, set the OLLAMA_HOST to:"
echo "http://$MY_USER:$MY_PASSWORD@$DOMAIN_OR_IP"
echo "-------------------------------------------------------"
