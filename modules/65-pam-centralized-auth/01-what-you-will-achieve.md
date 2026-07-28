## 🎯 What You Will Achieve

Authentication on Linux is controlled by PAM (Pluggable Authentication Modules) — a framework that lets you stack authentication methods, enforce password policies, and integrate with centralized directories like LDAP and Active Directory. Misconfigured PAM is one of the most common security vulnerabilities in Linux systems. This part teaches you to configure, secure, and troubleshoot PAM properly.

You will:

- Understand PAM architecture: module types, control flags, and the stacking order
- Configure PAM rules in `/etc/pam.d/` for authentication, session, and password management
- Use key PAM modules: `pam_unix`, `pam_sss`, `pam_ldap`, `pam_faillock`, `pam_google_authenticator`
- Enforce password policies: complexity, aging, history, and retry limits
- Understand SSSD architecture: providers, backend, monitor, and offline caching
- Configure LDAP authentication with OpenLDAP and StartTLS
- Use `authselect` to manage PAM profiles instead of hand-editing files
- Join a FreeIPA/Active Directory domain with SSSD
- Debug authentication failures with SSSD debug logs and PAM tracing
- Harden PAM against brute force, account enumeration, and privilege escalation





[↑ Index](index.md) | [Next →](02-1-what-is-pam-pluggable.md)
