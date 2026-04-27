## 2025-05-14 - Hardcoded Default Credentials and Overly Permissive Workspaces
**Vulnerability:** Deployment scripts contained hardcoded default passwords and created shared workspaces with `chmod 777` permissions.
**Learning:** Initial setup scripts often use placeholder credentials that users might forget to change, and "quick-start" permissions (777) are frequently used to avoid path issues, creating significant local security risks.
**Prevention:** Implement mandatory checks for default passwords in scripts and follow the principle of least privilege for file system permissions (e.g., 750 instead of 777). Use secure input methods for password generation (like `htpasswd -i`).

## 2025-05-15 - Insecure Wildcard CORS and Missing Security Headers
**Vulnerability:** Ollama was configured with `OLLAMA_ORIGINS=*` in systemd units, and reverse proxy templates lacked standard security headers (X-Frame-Options, etc.).
**Learning:** Defaulting to wildcard CORS in deployment scripts to "make it work" bypasses the reverse proxy's security role. Additionally, proxies must explicitly strip the 'Origin' header to prevent the backend from attempting its own CORS validation.
**Prevention:** Remove `OLLAMA_ORIGINS` from systemd overrides to use Ollama's secure defaults. Standardize security headers across all proxy types (Nginx, Apache, Caddy, etc.) and strip the 'Origin' header before forwarding to ensure the proxy remains the sole authenticated entry point.
