# Windows Secure Deployment Script
# Run as Administrator

param (
    [Parameter(Mandatory=$true)][string]$Domain,
    [Parameter(Mandatory=$true)][string]$Username,
    [Parameter(Mandatory=$true)][string]$Password
)

# 1. Check for Admin Rights
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this PowerShell window as Administrator."
    exit
}

# 2. Secure Ollama Environment
Write-Host "Configuring Ollama to listen only on localhost..."
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "127.0.0.1", "Machine")

# 3. Install/Check Caddy
if (!(Get-Command caddy -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Caddy via Winget..."
    winget install --id Caddy.Caddy -e --source winget
}

# 4. Generate Hash and Config
$HashedPwd = (caddy hash-password --plaintext $Password).Trim()
$CaddyConfigDir = "C:\Caddy"
if (!(Test-Path $CaddyConfigDir)) { New-Item -ItemType Directory -Path $CaddyConfigDir }

$Caddyfile = @"
$Domain {
    basicauth /* {
        $Username $HashedPwd
    }

    handle /api/* {
        reverse_proxy 127.0.0.1:11434
    }

    handle /* {
        reverse_proxy 127.0.0.1:3000
    }
}
"@

Set-Content -Path "$CaddyConfigDir\Caddyfile" -Value $Caddyfile

# 5. Firewall Configuration
Write-Host "Opening web ports and blocking direct Ollama access..."
# Allow HTTP/HTTPS
New-NetFirewallRule -DisplayName "Caddy-Inbound-HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow -Confirm:$false
New-NetFirewallRule -DisplayName "Caddy-Inbound-HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow -Confirm:$false
# Explicitly Block Ollama from External IPs
New-NetFirewallRule -DisplayName "Block-External-Ollama" -Direction Inbound -LocalPort 11434 -Protocol TCP -Action Block -Confirm:$false

# 6. Run Caddy
Write-Host "Starting Caddy in background..."
# Using 'caddy start' which runs Caddy in the background.
# Note: For production use, it is recommended to set up Caddy as a proper service using NSSM or similar.
caddy start --config "$CaddyConfigDir\Caddyfile"

Write-Host "Deployment finished. Restart the Ollama application for changes to take effect."
