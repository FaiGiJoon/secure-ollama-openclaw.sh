## 2025-05-14 - Hardcoded Default Credentials and Overly Permissive Workspaces
**Vulnerability:** Deployment scripts contained hardcoded default passwords and created shared workspaces with `chmod 777` permissions.
**Learning:** Initial setup scripts often use placeholder credentials that users might forget to change, and "quick-start" permissions (777) are frequently used to avoid path issues, creating significant local security risks.
**Prevention:** Implement mandatory checks for default passwords in scripts and follow the principle of least privilege for file system permissions (e.g., 750 instead of 777). Use secure input methods for password generation (like `htpasswd -i`).

## 2025-05-15 - Insecure CORS Wildcards and Origin Leakage
**Vulnerability:** Ollama was configured with `OLLAMA_ORIGINS=*`, allowing any website to make cross-origin requests to the local service.
**Learning:** Wildcard CORS is a significant risk for local services accessible via a browser. While needed for some frontend-backend setups, it can be avoided by having the reverse proxy strip the `Origin` header.
**Prevention:** Remove `OLLAMA_ORIGINS=*` and configure the reverse proxy to set `Origin ""` when forwarding to the backend. This tricks the backend into thinking it's a same-origin request while maintaining security.
