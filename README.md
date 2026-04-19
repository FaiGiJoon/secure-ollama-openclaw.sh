# Secure Ollama + OpenClaw Suite

This repository contains deployment scripts and reverse proxy configurations designed to secure local Ollama and OpenClaw installations across Linux, Windows, and MacOS. It remediates unauthenticated access vulnerabilities by forcing all traffic through a secure Reverse Proxy with Basic Authentication and optimized streaming.

## Security Features

- **Localhost Binding:** Automatically configures Ollama to bind to `127.0.0.1`, making the API invisible to untrusted networks and preventing direct access on port `11434`.
- **Reverse Proxy:** Acts as a gatekeeper for both the Ollama API and the OpenClaw Dashboard, consolidating them into a single secure entry point.
- **Basic Auth:** Enforces a username and password requirement before any data is exchanged with the backend services.
- **Stream Optimization:** Disables proxy buffering and adjusts timeouts to ensure AI responses stream word-by-word without latency or interruptions.
- **CORS Handling:** Pre-configured headers to allow the OpenClaw frontend to communicate seamlessly with the Ollama backend.

## Supported Proxies

The `proxies/` directory contains standardized configurations for:
- **Nginx:** High-performance, classic choice.
- **Caddy:** Automatic HTTPS and simple configuration.
- **HAProxy:** Reliable Layer 4/7 load balancing.
- **Apache:** Flexible and widely used.
- **Traefik:** Cloud-native with Docker support.
- **Envoy:** Designed for complex, distributed systems.
- **Kong:** API-focused gateway.

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
- **Public Entry Point:** Standardized routing:
  - OpenClaw Dashboard: `http://your-server-ip/`
  - Ollama API: `http://your-server-ip/ollama/`

## Cloud-Native Options

For deployments in AWS or Azure, you can use managed load balancers:

### AWS Application Load Balancer (ALB)
1. Create a Target Group for OpenClaw (Port 3000) and Ollama (Port 11434).
2. Configure Listener Rules:
   - `IF Path is /ollama* THEN Forward to Ollama Target Group` (Enable Group-level stickiness if needed).
   - `DEFAULT THEN Forward to OpenClaw Target Group`.
3. Use AWS WAF or ALB Listener Rules to enforce Authentication (OIDC/Cognito).

### Azure Application Gateway
1. Create Backend Pools for each service.
2. Use Path-based Routing Rules:
   - Path `/ollama/*` -> Ollama Backend.
   - Path `/*` -> OpenClaw Backend.
3. Enable WAF and use Azure AD for authentication.

## OpenClaw Configuration

Inside the OpenClaw dashboard settings, ensure your Ollama Host is set to:
`http://127.0.0.1:11434` (for local communication) or the authenticated proxy URL.
