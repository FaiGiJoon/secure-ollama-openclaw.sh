## 2025-05-14 - Hardcoded Default Credentials and Overly Permissive Workspaces
**Vulnerability:** Deployment scripts contained hardcoded default passwords and created shared workspaces with `chmod 777` permissions.
**Learning:** Initial setup scripts often use placeholder credentials that users might forget to change, and "quick-start" permissions (777) are frequently used to avoid path issues, creating significant local security risks.
**Prevention:** Implement mandatory checks for default passwords in scripts and follow the principle of least privilege for file system permissions (e.g., 750 instead of 777). Use secure input methods for password generation (like `htpasswd -i`).

## 2025-05-15 - Insecure Wildcard CORS and Origin Header Exposure
**Vulnerability:** Use of `OLLAMA_ORIGINS=*` allowed any website to make cross-origin requests to local Ollama APIs.
**Learning:** While wildcard CORS is a common "quick fix" for development, it creates a significant risk in local AI deployments. Simply removing it can break legitimate Web UI access if the proxy passes the browser's `Origin` header, as Ollama correctly rejects it for security.
**Prevention:** Remove `OLLAMA_ORIGINS=*` and configure reverse proxies to explicitly strip or clear the `Origin` header before forwarding requests to the Ollama backend. This ensures the proxy remains the sole authenticated and trusted gateway.
