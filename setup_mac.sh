#!/bin/bash
# MacOS Secure Deployment Script

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

DOMAIN=$1
USER=$2
PASS=$3

if [[ -z "$DOMAIN" || -z "$USER" || -z "$PASS" ]]; then
    echo "Usage: sudo ./setup_mac.sh <domain> <username> <password>"
    exit 1
fi

# Detect Homebrew Path
BREW_PATH="/usr/local/bin/brew"
[[ -f "/opt/homebrew/bin/brew" ]] && BREW_PATH="/opt/homebrew/bin/brew"

# Fix: Ensure Ollama binds to localhost only
# This creates a global environment variable for the Ollama service
echo "Setting OLLAMA_HOST to 127.0.0.1..."
# Persistence using launchctl config (requires reboot)
launchctl config user setenv OLLAMA_HOST "127.0.0.1"
# Immediate effect for current session
launchctl setenv OLLAMA_HOST "127.0.0.1"

# Install Caddy
if ! command -v caddy &> /dev/null; then
    sudo -u $(logname) $BREW_PATH install caddy
fi

# Generate password hash
HASHED_PWD=$(caddy hash-password --plaintext "$PASS")

# Configuration
CADDY_DIR="/etc/caddy"
mkdir -p "$CADDY_DIR"

cat <<EOF > "$CADDY_DIR/Caddyfile"
$DOMAIN {
    basicauth /* {
        $USER $HASHED_PWD
    }

    handle /api/* {
        reverse_proxy 127.0.0.1:11434
    }

    handle /* {
        reverse_proxy 127.0.0.1:3000
    }
}
EOF

# Use 'brew services' as the user to start caddy
# If running as root, we should specify the user
USER_NAME=$(logname)
sudo -u $USER_NAME $BREW_PATH services restart caddy

echo "Setup complete. Ensure Ollama is restarted to pick up the 127.0.0.1 binding."
echo "You may need to logout and login for the OLLAMA_HOST variable to persist."
