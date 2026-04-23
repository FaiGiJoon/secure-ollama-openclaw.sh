## 2025-05-14 - Hardcoded Default Credentials and Overly Permissive Workspaces
**Vulnerability:** Deployment scripts contained hardcoded default passwords and created shared workspaces with `chmod 777` permissions.
**Learning:** Initial setup scripts often use placeholder credentials that users might forget to change, and "quick-start" permissions (777) are frequently used to avoid path issues, creating significant local security risks.
**Prevention:** Implement mandatory checks for default passwords in scripts and follow the principle of least privilege for file system permissions (e.g., 750 instead of 777). Use secure input methods for password generation (like `htpasswd -i`).

## 2025-05-15 - Insecure CORS Wildcards and Missing Security Headers
**Vulnerability:** Deployment scripts used `OLLAMA_ORIGINS=*` which bypassed CORS security, and proxy templates lacked standard security headers and version disclosure protection.
**Learning:** Wildcard CORS is often used as a "quick fix" for connectivity issues but exposes the API to cross-site attacks. Proxies should instead strip the `Origin` header to safely handle requests while keeping the backend secure.
**Prevention:** Remove `OLLAMA_ORIGINS` wildcards. Configure proxies to clear the `Origin` header, disable server tokens, and enforce standard security headers (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`).
