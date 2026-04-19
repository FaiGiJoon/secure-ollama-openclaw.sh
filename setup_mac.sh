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
echo "Setting OLLAMA_HOST to 127.0.0.1..."
launchctl config user setenv OLLAMA_HOST "127.0.0.1"
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

# Use the standardized template from proxies/caddy/
cp proxies/caddy/Caddyfile "$CADDY_DIR/Caddyfile"

# Inject values
sed -i "" "s/yourdomain.com/$DOMAIN/" "$CADDY_DIR/Caddyfile"
sed -i "" "s/admin/$USER/" "$CADDY_DIR/Caddyfile"
sed -i "" "s|JDJhJDE0JDd2a3Z3...|$HASHED_PWD|" "$CADDY_DIR/Caddyfile"

# Use 'brew services' as the user to start caddy
USER_NAME=$(logname)
sudo -u $USER_NAME $BREW_PATH services restart caddy

echo "Setup complete. Ensure Ollama is restarted to pick up the 127.0.0.1 binding."
echo "You may need to logout and login for the OLLAMA_HOST variable to persist."
