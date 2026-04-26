## 2025-05-14 - Hardcoded Default Credentials and Overly Permissive Workspaces
**Vulnerability:** Deployment scripts contained hardcoded default passwords and created shared workspaces with `chmod 777` permissions.
**Learning:** Initial setup scripts often use placeholder credentials that users might forget to change, and "quick-start" permissions (777) are frequently used to avoid path issues, creating significant local security risks.
**Prevention:** Implement mandatory checks for default passwords in scripts and follow the principle of least privilege for file system permissions (e.g., 750 instead of 777). Use secure input methods for password generation (like `htpasswd -i`).

## 2026-04-26 - Insecure Wildcard CORS via OLLAMA_ORIGINS
**Vulnerability:** Setting `OLLAMA_ORIGINS=*` in systemd units bypasses the reverse proxy's security posture by allowing any Origin to interact with the API if the proxy is misconfigured or bypassed.
**Learning:** Ollama's internal CORS handling can be overly permissive when using wildcards. Stripping the `Origin` header at the proxy level forces Ollama to treat requests as "same-origin" or non-CORS, effectively delegating all CORS and authentication decisions to the secure reverse proxy.
**Prevention:** Remove `OLLAMA_ORIGINS` environment variables from deployment scripts and configure all reverse proxies (Nginx, Apache, Caddy, HAProxy, Envoy, Kong) to strip the `Origin` header before forwarding requests to the Ollama backend.
