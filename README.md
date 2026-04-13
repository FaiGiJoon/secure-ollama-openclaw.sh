# Secure Ollama + OpenClaw Suite

This repository contains deployment scripts designed to secure local Ollama and OpenClaw installations across Linux, Windows, and MacOS. It specifically remediates unauthenticated access vulnerabilities by forcing all traffic through a secure Reverse Proxy (Nginx, Caddy, or HAProxy) with Basic Authentication.

## Security Features

- **Localhost Binding:** Automatically configures Ollama to bind to `127.0.0.1`, making the API invisible to untrusted networks and preventing direct access on port `11434`.
- **Reverse Proxy:** Acts as a gatekeeper for both the Ollama API and the OpenClaw Dashboard, consolidating them into a single secure entry point.
- **Basic Auth:** Enforces a username and password requirement before any data is exchanged with the backend services.
- **Stream Optimization:** Disables proxy buffering to ensure AI responses stream word-by-word without latency.
- **CORS Handling:** Pre-configured headers to allow the OpenClaw frontend to communicate seamlessly with the Ollama backend on the same host.

## Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/FaiGiJoon/secure-ollama-openclaw.sh.git
cd secure-ollama-openclaw.sh
```

### 2. Choose your platform and run the installer

#### Linux (Nginx)
Edit the `MY_USER` and `MY_PASSWORD` variables in the script first.
```bash
chmod +x TwoPathNginx.sh
sudo ./TwoPathNginx.sh
```

#### Windows (Caddy)
Run in an Administrator PowerShell window:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup_windows.ps1 -Domain "yourdomain.com" -Username "admin" -Password "YourSecurePassword"
```

#### MacOS (Caddy)
```bash
chmod +x setup_mac.sh
sudo ./setup_mac.sh "yourdomain.com" "admin" "YourSecurePassword"
```

## Architecture

- **Ollama API:** Runs on `127.0.0.1:11434` (Internal loopback only)
- **OpenClaw Dashboard:** Runs on `127.0.0.1:3000` (Internal loopback only)
- **Public Entry Point:** Port `80` / `443` (Controlled and authenticated by the Reverse Proxy)

Once the script finishes, you can access your dashboard at `http://your-server-ip` or your configured domain. You will be prompted for the credentials you defined.

## OpenClaw Configuration

Inside the OpenClaw dashboard settings, ensure your Ollama Host is set to:
`http://127.0.0.1:11434`

Note: Since both services reside on the same machine, OpenClaw communicates with Ollama internally via the loopback interface, while the reverse proxy protects the external access point.
