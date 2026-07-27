## 1. What Is PAM — Pluggable Authentication Modules

### The Problem PAM Solves

Before PAM, every program that needed to authenticate a user (login, sshd, sudo, su, passwd) had its own authentication code. Changing the password mechanism meant recompiling every program. PAM fixed this by creating a **pluggable framework**:

```
┌──────────────────────────────────────────────────────────┐
│                    BEFORE PAM                              │
│                                                            │
│  login ──→ hardcoded /etc/passwd check                    │
│  sshd  ──→ hardcoded /etc/passwd check                    │
│  sudo  ──→ hardcoded /etc/passwd check                    │
│  su    ──→ hardcoded /etc/passwd check                    │
│                                                            │
│  Change auth method = recompile ALL programs               │
├──────────────────────────────────────────────────────────┤
│                    WITH PAM                                 │
│                                                            │
│  login ──→ PAM library ──→ [ module1, module2, ... ]      │
│  sshd  ──→ PAM library ──→ [ module1, module2, ... ]      │
│  sudo  ──→ PAM library ──→ [ module1, module2, ... ]      │
│  su    ──→ PAM library ──→ [ module1, module2, ... ]      │
│                                                            │
│  Change auth method = swap/configure modules               │
└──────────────────────────────────────────────────────────┘
```

### PAM Architecture

The PAM framework has three layers:

```
┌─────────────────────────────────────────────────────────┐
│  APPLICATION LAYER                                        │
│  login, sshd, sudo, su, passwd, gdm, ...                 │
├─────────────────────────────────────────────────────────┤
│  PAM LIBRARY (libpam)                                     │
│  /lib64/libpam.so.*                                       │
│  Reads /etc/pam.d/<service> configs                       │
│  Chains modules together                                   │
├─────────────────────────────────────────────────────────┤
│  MODULE LAYER                                             │
│  pam_unix.so    → local /etc/shadow auth                  │
│  pam_sss.so     → SSSD (LDAP/AD/Kerberos)               │
│  pam_ldap.so    → direct LDAP auth (legacy)               │
│  pam_faillock.so → brute-force lockout                   │
│  pam_google_authenticator.so → TOTP 2FA                  │
│  pam_limits.so  → ulimit enforcement                     │
│  pam_tally2.so  → login attempt counting (deprecated)    │
└─────────────────────────────────────────────────────────┘
```

### The Authentication Flow

```
User types password at login prompt
         │
         ▼
┌─────────────────────────┐
│  Application calls       │
│  pam_authenticate()      │
├─────────────────────────┤
│  PAM reads               │
│  /etc/pam.d/login        │
├─────────────────────────┤
│  For each "auth" line:   │
│  ┌──────────────────┐    │
│  │ pam_faillock.so  │──→│ Check if account locked
│  │ success=OK       │    │
│  └──────────────────┘    │
│  ┌──────────────────┐    │
│  │ pam_unix.so      │──→│ Check /etc/shadow
│  │ success=OK       │    │
│  └──────────────────┘    │
│  ┌──────────────────┐    │
│  │ pam_sss.so       │──→│ Forward to SSSD → LDAP
│  │ optional          │    │
│  └──────────────────┘    │
├─────────────────────────┤
│  All required modules    │
│  must succeed → GRANT    │
│  Any required fails → DENY│
└─────────────────────────┘
```

> 🔍 **Reverse Engineering Insight:** PAM is just a library (`libpam.so`), not a daemon. Applications link against it. There is no "PAM service" running — when `sshd` authenticates a user, it calls `pam_authenticate()` in-process, which reads the config file and loads `.so` modules directly into the `sshd` process space.

---



---

[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-2-pam-configuration-etcpamd.md)
