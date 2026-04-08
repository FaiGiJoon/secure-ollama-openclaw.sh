# Secure Ollama + OpenClaw Suite

This repository contains a deployment script designed to secure local Ollama and OpenClaw installations. It specifically remediates the Unauthenticated Access vulnerability (Tenable Plugin ID 302134) by forcing all traffic through an Nginx Reverse Proxy with Basic Authentication.

## Security Features

- **Localhost Binding:** Automatically configures Ollama to bind to 127.0.0.1, making the API invisible to untrusted networks and preventing direct access on port 11434.
- **Nginx Reverse Proxy:** Acts as a gatekeeper for both the Ollama API and the OpenClaw Dashboard, consolidating them into a single secure entry point.
- **Basic Auth:** Enforces a username and password requirement at the Nginx level before any data is exchanged with the backend services.
- **Stream Optimization:** Disables Nginx proxy buffering to ensure AI responses stream word-by-word without latency.
- **CORS Handling:** Pre-configured headers to allow the OpenClaw frontend to communicate seamlessly with the Ollama backend on the same host.

## Quick Start

### 1. Clone the repository
```bash
git clone [https://github.com/FaiGiJoon/secure-ollama-openclaw.sh.git](https://github.com/FaiGiJoon/secure-ollama-openclaw.sh.git)
cd secure-ollama-openclaw.sh
2. Configure the script
Open the script and edit the MY_USER and MY_PASSWORD variables to set your secure credentials.

Bash
nano secure-ollama-openclaw.sh
3. Run the installer
Make the script executable and run it with sudo privileges:

Bash
chmod +x secure-ollama-openclaw.sh
sudo ./secure-ollama-openclaw.sh
Architecture
Ollama API: Runs on 127.0.0.1:11434 (Internal loopback only)

OpenClaw Dashboard: Runs on 127.0.0.1:9090 (Internal loopback only)

Public Entry Point: Port 80 (Controlled and authenticated by Nginx)

Once the script finishes, you can access your dashboard at http://your-server-ip. You will be prompted for the credentials you defined in the script.

OpenClaw Configuration
Inside the OpenClaw dashboard settings, ensure your Ollama Host is set to:
http://127.0.0.1:11434

Note: Since both services reside on the same machine, OpenClaw communicates with Ollama internally via the loopback interface. Nginx handles the external security layer, ensuring no unauthenticated traffic reaches either service.

Remediation Verification
To verify that the Tenable 302134 vulnerability (Unauthenticated Access) is resolved, run the following command on the host:

Bash
sudo ss -tulpn | grep 11434
Required Result: The output should show the service listening on 127.0.0.1:11434.
Vulnerable Result: If the output shows 0.0.0.0:11434 or :::11434, the service is still exposed to the network and further hardening is required.
