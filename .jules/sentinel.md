## 2025-05-14 - Hardcoded Default Credentials and Overly Permissive Workspaces
**Vulnerability:** Deployment scripts contained hardcoded default passwords and created shared workspaces with `chmod 777` permissions.
**Learning:** Initial setup scripts often use placeholder credentials that users might forget to change, and "quick-start" permissions (777) are frequently used to avoid path issues, creating significant local security risks.
**Prevention:** Implement mandatory checks for default passwords in scripts and follow the principle of least privilege for file system permissions (e.g., 750 instead of 777). Use secure input methods for password generation (like `htpasswd -i`).
