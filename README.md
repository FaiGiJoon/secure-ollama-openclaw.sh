# secure-ollama-openclaw.sh
# Secure Ollama + OpenClaw Suite

This repository contains a deployment script designed to secure local Ollama and OpenClaw installations. It addresses the Unauthenticated Access vulnerability (Tenable Plugin ID 302134) by forcing all traffic through an Nginx Reverse Proxy with Basic Authentication.

## Security Features

- **Localhost Binding:** Automatically configures Ollama to bind to 127.0.0.1, making the API invisible to untrusted networks.
- **Nginx Reverse Proxy:** Acts as a gatekeeper for both the Ollama API and the OpenClaw Dashboard.
- **Basic Auth:** Enforces a username and password requirement before any data is exchanged.
- **Stream Optimization:** Disables Nginx proxy buffering to ensure AI responses stream word-by-word without lag.
- **CORS Handling:** Pre-configured headers to allow the OpenClaw frontend to communicate seamlessly with the Ollama backend.

## Quick Start

### 1. Clone the repository
```bash
git clone [https://github.com/FaiGiJoon/secure-ollama-openclaw.sh.git](https://github.com/FaiGiJoon/secure-ollama-openclaw.sh.git)
cd secure-ollama-openclaw.sh
2. Configure the script
Open the script and edit the MY_USER and MY_PASSWORD variables to your desired credentials.

Bash
nano secure-ollama-openclaw.sh
3. Run the installer
Make the script executable and run it with sudo privileges:

Bash
chmod +x secure-ollama-openclaw.sh
sudo ./secure-ollama-openclaw.sh
Architecture
Ollama API: Runs on 127.0.0.1:11434 (Internal only)

OpenClaw Dashboard: Runs on 127.0.0.1:9090 (Internal only)

Public Entry Point: Port 80 (Controlled by Nginx)

Once the script finishes, you can access your dashboard at http://your-server-ip. You will be prompted for the credentials you defined in the script.

OpenClaw Configuration
Inside the OpenClaw dashboard settings, set your Ollama Host to:
http://127.0.0.1:11434

Note: Since both services reside on the same machine, OpenClaw communicates with Ollama internally via the loopback interface, while Nginx protects the external access point.

## About

This project is provided for security hardening purposes. Nginx Open Source is used under the BSD-2-Clause license.