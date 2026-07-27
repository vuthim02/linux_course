# 🐧 Linux System Administrator — Complete Course
## Part 65 of ∞: PAM & Centralized Authentication — SSSD, LDAP, and authselect

---

> **Reverse Engineering Approach:** When a user can't log in via SSH but works at the console, when `su` silently fails, when you need to centralize credentials across 500 servers — you need to understand PAM from the inside. This part takes apart the Pluggable Authentication Modules framework, traces every login through the PAM stack, deconstructs SSSD's caching architecture, configures LDAP integration, and uses authselect to manage it all. By the end, you'll be able to build, debug, and secure any authentication flow on a Linux system.

---

## 🎯 What You Will Achieve

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

---

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

## 2. PAM Configuration — `/etc/pam.d/`

### Directory Structure

```bash
# PAM configuration directory
ls /etc/pam.d/

# Typical contents on RHEL/Fedora:
# chsh  fingerprint-auth  login       password-auth  runuser    sssd-shadowutils
# chfn  fingerprint-auth-ac  polkit-1  runuser-l    smartcard-auth
# cockpit  login  postlogin  remote  sshd  su  sudo  sudo-i  system-auth

# On Debian/Ubuntu:
# common-auth  common-password  common-session  common-session-noninteractive
# login  sshd  su  sudo  polkit-1
```

### Configuration File Format

Each line in a PAM config file follows this format:

```
<module_type>  <control_flag>  <module_path>  [module_arguments...]
```

### The Four Module Types

```
┌──────────────────────────────────────────────────────────┐
│  MODULE TYPE    │  PURPOSE                                │
├──────────────────────────────────────────────────────────┤
│  auth           │  Verify the user's identity            │
│                 │  (password, biometric, token)           │
├──────────────────────────────────────────────────────────┤
│  account        │  Check if the account is valid         │
│                 │  (expired, locked, allowed time)        │
├──────────────────────────────────────────────────────────┤
│  password       │  Handle password changes               │
│                 │  (complexity, aging, history)           │
├──────────────────────────────────────────────────────────┤
│  session        │  Set up / tear down user session        │
│                 │  (limits, umask, home dir, logging)     │
└──────────────────────────────────────────────────────────┘
```

### Control Flags — How PAM Chains Results

```
┌──────────────────────────────────────────────────────────┐
│  CONTROL FLAG  │  BEHAVIOR                                │
├──────────────────────────────────────────────────────────┤
│  required       │  Must pass. If fails, continue checking │
│                 │  but最终 result is always failure.       │
│                 │  Failure message delayed to prevent     │
│                 │  user enumeration.                       │
├──────────────────────────────────────────────────────────┤
│  requisite      │  Must pass. If fails, IMMEDIATELY       │
│                 │  return failure. No further checks.     │
├──────────────────────────────────────────────────────────┤
│  sufficient     │  If passes AND no prior required has    │
│                 │  failed, return success immediately.    │
│                 │  If fails, ignore and continue.         │
├──────────────────────────────────────────────────────────┤
│  optional       │  Success doesn't matter unless it's    │
│                 │  the ONLY module of that type.          │
├──────────────────────────────────────────────────────────┤
│  include        │  Include another PAM config file        │
├──────────────────────────────────────────────────────────┤
│  substack       │  Like include, but count failures      │
│                 │  as one module.                          │
├──────────────────────────────────────────────────────────┤
│  requisite      │  Immediate failure return               │
│  (advanced)     │  Use "syntax=value" to specify action   │
│                 │  on failure: [success=done new_authtok...│
└──────────────────────────────────────────────────────────┘
```

### Example: RHEL `/etc/pam.d/system-auth`

```bash
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authselect is run.

auth        required      pam_env.so
auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900
auth        sufficient    pam_unix.so nullok try_first_pass
auth        [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900
auth        sufficient    pam_sss.so forward_pass
auth        required      pam_deny.so

account     required      pam_unix.so
account     sufficient    pam_localuser.so
account     sufficient    pam_sss.so
account     required      pam_permit.so

password    requisite     pam_pwquality.so local_users_only retry=3
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient    pam_sss.so use_authtok
password    required      pam_deny.so

session     required      pam_limits.so
session     required      pam_namespace.so
session     optional      pam_oddjob_mkhomedir.so skel=/etc/skel umask=077
session     optional      pam_sss.so
session     required      pam_unix.so
```

> ⚠️ **Warning:** Never hand-edit PAM configuration files on RHEL/Fedora — they are managed by `authselect`. Manual edits will be overwritten. Use `authselect` profiles and custom features instead (covered in Section 7).

### Example: Debian `/etc/pam.d/common-auth`

```bash
# /etc/pam.d/common-auth
auth    [success=2 default=ignore]      pam_unix.so nullok
auth    [success=1 default=ignore]      pam_sss.so use_first_pass
auth    requisite                       pam_deny.so
auth    required                        pam_permit.so
```

### Service-to-Config Mapping

When `sshd` calls `pam_authenticate()`, PAM reads `/etc/pam.d/sshd`. The mapping is simple:

```
Application binary name → /etc/pam.d/<name>

sshd    → /etc/pam.d/sshd
login   → /etc/pam.d/login
sudo    → /etc/pam.d/sudo
su      → /etc/pam.d/su
passwd  → /etc/pam.d/passwd
```

> 🔍 **Reverse Engineering Insight:** `pam_authenticate()` takes a service name as its first argument. The application passes its own name (e.g., "sshd"), which tells PAM which config file to read. This is why the binary name matters — renaming `ssd` would break its PAM config lookup.

---

## 3. PAM Modules Deep Dive

### pam_unix — The Foundation

`pam_unix.so` authenticates against the local `/etc/shadow` file. It is the default and most common module.

```bash
# Standard usage
auth    sufficient    pam_unix.so nullok try_first_pass

# Module arguments:
# nullok          - allow users with empty passwords
# try_first_pass  - use password from previous module (avoid re-prompting)
# use_first_pass  - use password from previous module (no re-prompting)
# shadow           - use /etc/shadow
# md5              - use MD5 hashing (deprecated)
# sha512           - use SHA-512 hashing
# remember=N       - remember last N passwords (history)
# rounds=N         - number of rounds for SHA crypt
# bigcrypt         - use BIGCRYPT (legacy)
```

```bash
# Password change configuration
password  sufficient  pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5

# use_authtok = don't prompt for new password, use what PAM already has
# remember=5 = last 5 passwords cannot be reused
```

### pam_sss — SSSD Bridge

`pam_sss.so` delegates authentication to the SSSD daemon, which handles LDAP, Kerberos, or Active Directory backends.

```bash
# Authentication through SSSD
auth    sufficient    pam_sss.so forward_pass

# forward_pass = pass the originally entered password to the next module
#                 instead of re-prompting

# Session setup through SSSD
session optional      pam_sss.so

# Password change through SSSD
password sufficient  pam_sss.so use_authtok

# Account checks through SSSD
account sufficient    pam_sss.so
```

### pam_ldap — Direct LDAP (Legacy)

```bash
# Direct LDAP authentication (NOT recommended — use SSSD instead)
auth    required    pam_ldap.so use_first_pass
password required   pam_ldap.so
account required    pam_ldap.so
```

> ⚠️ **Warning:** `pam_ldap.so` is considered legacy. It makes direct LDAP queries without caching, offline support, or Kerberos integration. Always prefer `pam_sss.so` which handles all of this through the SSSD daemon.

### pam_faillock — Brute Force Protection

`pam_faillock.so` tracks failed login attempts and locks accounts after a threshold.

```bash
# Pre-auth: check if account is already locked
auth    required    pam_faillock.so preauth silent audit deny=5 unlock_time=900

# Auth failure: record the failed attempt
auth    [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900

# Account check: verify lock status
account required    pam_faillock.so
```

```bash
# Key arguments:
# deny=N          - lock after N failed attempts (default: 5)
# unlock_time=N   - auto-unlock after N seconds (0 = permanent)
# fail_interval=N - window for counting failures (default: 900s)
# audit           - log username to syslog
# silent          - suppress messages during preauth

# Manually check/reset faillock
sudo faillock --user john
sudo faillock --user john --reset
```

```bash
# Example: lock after 3 failures, unlock after 10 minutes
auth    required    pam_faillock.so preauth silent audit deny=3 unlock_time=600
auth    [default=die] pam_faillock.so authfail audit deny=3 unlock_time=600
```

### pam_google_authenticator — TOTP Two-Factor

```bash
# Install on RHEL/Fedora
sudo dnf install google-authenticator

# Install on Debian/Ubuntu
sudo apt install libpam-google-authenticator

# PAM configuration
auth    required    pam_google_authenticator.so forward_pass

# The user runs: google-authenticator to set up their TOTP secret
# This creates ~/.google_authenticator with the secret key
```

```bash
# arguments:
# forward_pass      - concatenate password+OTP before passing to next module
# use_first_pass    - read OTP from previous module's password field
# no_increment_hotp - don't increment HOTP counter on success
```

### Other Important Modules

```bash
# pam_limits.so — enforce resource limits from /etc/security/limits.conf
session required    pam_limits.so

# pam_namespace.so — isolate user sessions with polyinstantiated dirs
session required    pam_namespace.so

# pam_mkhomedir.so — create home directory on first login
session optional    pam_mkhomedir.so skel=/etc/skel umask=077

# pam_oddjob_mkhomedir.so — create home dir via oddjobd (RHEL, with SELinux)
session optional    pam_oddjob_mkhomedir.so

# pam_tally2.so — DEPRECATED, replaced by pam_faillock.so
# pam_access.so — check /etc/access.conf for host/user restrictions
account required    pam_access.so

# pam_time.so — restrict login times per /etc/security/time.conf
account required    pam_time.so

# pam_securetty.so — restrict root login to /etc/securetty
auth    required    pam_securetty.so

# pam_rootok.so — succeed only if UID is 0 (root)
auth    sufficient  pam_rootok.so

# pam_deny.so — always deny (used as a catch-all at end of stack)
auth    required    pam_deny.so

# pam_permit.so — always permit (use carefully!)
auth    required    pam_permit.so
```

> 🔍 **Reverse Engineering Insight:** PAM modules are shared objects (`.so` files) loaded at runtime. You can see exactly which modules are loaded with: `cat /proc/<sshd_pid>/maps | grep pam_`. This reveals the actual module files linked into a running process.

---

## 4. Password Policies

### pam_pwquality — Complexity Enforcement

```bash
# /etc/pam.d/system-auth (or common-password on Debian)
password  requisite  pam_pwquality.so retry=3

# /etc/security/pwquality.conf
# Minimum password length
minlen = 14

# Require at least one of each:
dcredit = -1    # at least 1 digit
ucredit = -1    # at least 1 uppercase letter
lcredit = -1    # at least 1 lowercase letter
ocredit = -1    # at least 1 special character

# Maximum consecutive identical characters
maxrepeat = 3

# Maximum consecutive characters from same class
maxclassrepeat = 4

# Check for dictionary words
dictcheck = 1

# Check if password contains user name
usercheck = 1

# Number of retries
retry = 3

# Reject passwords shorter than this regardless of other settings
minlen = 14
```

```bash
# Enforce for root too (root is exempt by default on RHEL)
enforce_for_root

# Local users only (skip for LDAP/SSSD users — they use server-side policy)
local_users_only
```

### Password Aging — /etc/shadow Fields

```bash
# View password aging for a user
sudo chage -l john

# Output:
# Last password change                    : Jul 15, 2026
# Password expires                        : Oct 13, 2026
# Number of days of warning               : 7
# Number of days before password is inactive : 14
# Number of days after password expires       : 30
# Account expires                             : Aug 31, 2026

# Set password aging
sudo chage -M 90 -m 7 -W 14 john
# -M 90  = password expires in 90 days
# -m 7   = minimum 7 days between changes
# -W 14  = warn 14 days before expiry
```

```bash
# Global defaults in /etc/login.defs
PASS_MAX_DAYS   90      # Maximum password age
PASS_MIN_DAYS   7       # Minimum days between changes
PASS_MIN_LEN    14      # Minimum length (pam_pwquality overrides)
PASS_WARN_AGE   14      # Days before expiry to warn
```

### Password History — Prevent Reuse

```bash
# pam_unix remember=N
password  sufficient  pam_unix.so remember=5 use_authtok

# Also stored in /etc/security/opasswd
# This file tracks old password hashes per user

# Check history
cat /etc/security/opasswd
# john:$5$rounds=5000$oldhash1:1
# john:$5$rounds=5000$oldhash2:2
```

### Unified Password Policy Example

```bash
# Complete password policy stack
password  requisite   pam_pwquality.so retry=3 enforce_for_root
password  sufficient  pam_unix.so sha512 shadow remember=5 use_authtok
password  sufficient  pam_sss.so use_authtok
password  required    pam_deny.so

# Combined with login.defs:
# PASS_MAX_DAYS=90  PASS_MIN_DAYS=7  PASS_WARN_AGE=14
```

> 🔍 **Reverse Engineering Insight:** When using SSSD with LDAP/AD, password complexity is often enforced server-side (AD Fine-Grained Password Policy or LDAP `ppolicy` overlay). The local `pam_pwquality` settings only apply to local password changes. If you configure `local_users_only`, SSSD delegates policy to the directory server.

---

## 5. SSSD Architecture

### What Is SSSD?

SSSD (System Security Services Daemon) is the modern bridge between Linux systems and centralized identity providers (LDAP, Active Directory, FreeIPA, Kerberos).

```
┌──────────────────────────────────────────────────────────┐
│                    APPLICATIONS                             │
│  login, sshd, sudo, su, getent, id, ...                   │
├──────────────────────────────────────────────────────────┤
│                    NSS / PAM                                │
│  nss_sss.so  →  name service switch (getent passwd)       │
│  pam_sss.so  →  authentication (pam_authenticate)         │
├──────────────────────────────────────────────────────────┤
│                    SSSD DAEMON                              │
│  ┌──────────────────────────────────────────────┐          │
│  │  sssd (monitor)                               │          │
│  │  Manages all child processes                  │          │
│  ├──────────────────────────────────────────────┤          │
│  │  sss_nss (NSS responder)                      │          │
│  │  Handles getent passwd, getent group, etc.    │          │
│  ├──────────────────────────────────────────────┤          │
│  │  sss_pam (PAM responder)                      │          │
│  │  Handles authentication requests              │          │
│  ├──────────────────────────────────────────────┤          │
│  │  sss_ssh (SSH responder)                      │          │
│  │  Provides SSH public keys from LDAP           │          │
│  ├──────────────────────────────────────────────┤          │
│  │  sss_sudo (Sudo responder)                    │          │
│  │  Provides sudo rules from LDAP                │          │
│  └──────────────────────────────────────────────┘          │
├──────────────────────────────────────────────────────────┤
│                    DATA PROVIDERS                           │
│  ┌──────────┐  ┌──────────────┐  ┌─────────────────┐     │
│  │ LDAP/ID  │  │ Kerberos/    │  │ Local Files      │     │
│  │ Provider │  │ AD Provider  │  │ Provider         │     │
│  │          │  │              │  │ (/etc/passwd)    │     │
│  └──────────┘  └──────────────┘  └─────────────────┘     │
├──────────────────────────────────────────────────────────┤
│                    CACHE (ldb database)                     │
│  /var/lib/sss/db/config.ldb  (SSSD configuration)         │
│  /var/lib/sss/mc/passwd.ldb  (memory cache)               │
│  /var/lib/sss/mc/group.ldb                                │
│  Enables OFFLINE authentication when LDAP is unreachable  │
└──────────────────────────────────────────────────────────┘
```

### SSSD Configuration — /etc/sssd/sssd.conf

```bash
# /etc/sssd/sssd.conf
# Permissions MUST be 0600 (SSSD refuses to start otherwise)
sudo chmod 600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf

# [sssd] section — global settings
[sssd]
domains = example.com
config_file_version = 2
services = nss, pam, ssh, sudo

# Domain configuration
[domain/example.com]
# Identity provider
id_provider = ldap

# Authentication provider
auth_provider = ldap

# Access provider (who can log in)
access_provider = ldap

# Chage provider (password changes)
chpass_provider = ldap

# Cache provider
cache_provider = ldap

# LDAP server URIs
ldap_uri = ldaps://ldap.example.com
ldap_backup_uri = ldaps://ldap-backup.example.com

# LDAP search bases
ldap_search_base = dc=example,dc=com
ldap_user_search_base = ou=People,dc=example,dc=com
ldap_group_search_base = ou=Groups,dc=example,dc=com

# Bind DN (service account for LDAP queries)
ldap_default_bind_dn = cn=readonly,ou=Service,dc=example,dc=com
ldap_default_authtok = P@ssw0rd123
ldap_default_authtok_type = password

# TLS settings
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/openldap/cacerts/ca.crt
ldap_tls_cacertdir = /etc/openldap/cacerts

# Schema settings
ldap_schema = rfc2307bis
ldap_user_object_class = posixAccount
ldap_user_name = uid
ldap_group_object_class = posixGroup
ldap_group_name = cn

# User and group maps
ldap_user_gecos = gecos
ldap_user_home_directory = homeDirectory
ldap_user_shell = loginShell
ldap_user_uid_number = uidNumber
ldap_group_member = member

# SSH key lookup
ldap_user_ssh_public_key = sshPublicKey

# Kerberos (if using Kerberos for auth)
# auth_provider = krb5
# krb5_server = kdc.example.com
# krb5_realm = EXAMPLE.COM
# krb5_kdcip = kdc.example.com

# Caching settings
entry_cache_timeout = 300
entry_cache_user_timeout = 300
entry_cache_group_timeout = 300

# Offline authentication
cache_credentials = true
krb5_store_password_if_offline = true

# Debugging (0=off, 1=critical, 3=info, 6=trace, 9=extreme)
debug_level = 3

# Access control
ldap_access_order = expire
ldap_account_expire_policy = shadow
```

### SSSD Providers Breakdown

```
┌───────────────────────────────────────────────────────────┐
│  PROVIDER TYPE   │  PURPOSE                                │
├───────────────────────────────────────────────────────────┤
│  id_provider      │  Get user/group info (UID, GID, home)  │
│  auth_provider    │  Authenticate the user (password/Kerb) │
│  access_provider  │  Allow/deny login (time, host, etc.)   │
│  chpass_provider  │  Change user password                   │
│  sudo_provider    │  Load sudo rules from LDAP             │
│  selinux_provider │  Load SELinux user mappings             │
│  autofs_provider  │  Automount map entries                  │
│  hostid_provider  │  Host identity                         │
│  subdomains_prov. │  Subdomain trusts (AD)                  │
└───────────────────────────────────────────────────────────┘
```

### SSSD Caching — How Offline Auth Works

```
┌──────────────────────────────────────────────────────────┐
│  FIRST LOGIN (online)                                      │
│  1. SSSD queries LDAP → gets user info + password hash    │
│  2. Stores in /var/lib/sss/db/config.ldb ( ldb )         │
│  3. Memory cache: /var/lib/sss/mc/passwd.ldb              │
│  4. Authenticated successfully                            │
├──────────────────────────────────────────────────────────┤
│  LDAP UNREACHABLE (offline)                                │
│  1. SSSD detects LDAP timeout                              │
│  2. Falls back to cached credentials                       │
│  3. Checks cached password hash (stored securely)         │
│  4. Authenticates offline if cache is valid                │
│  5. Logs "Going offline" to syslog                         │
├──────────────────────────────────────────────────────────┤
│  LDAP RESTORED (online again)                              │
│  1. SSSD detects LDAP is reachable                         │
│  2. Refreshes cache with fresh data from LDAP              │
│  3. Logs "Going online" to syslog                          │
│  4. Next login uses live LDAP data                         │
└──────────────────────────────────────────────────────────┘
```

```bash
# Check SSSD cache contents
sudo sss_cache -E                    # Expire all cached entries
sudo ldbsearch -H /var/lib/sss/db/config.ldb "(objectClass=user)" | head -50

# Check if SSSD is using cache
sudo sssctl domain-status example.com

# Force online check
sudo sssctl domain-status example.com --online
```

> 🔍 **Reverse Engineering Insight:** SSSD's memory cache (`/var/lib/sss/mc/`) is memory-mapped, meaning `getent passwd` reads directly from shared memory without even contacting the SSSD daemon. This is why `getent passwd <ldap_user>` is near-instant even with thousands of LDAP users.

---

## 6. LDAP Integration

### LDAP Basics

LDAP (Lightweight Directory Access Protocol) stores data in a hierarchical tree:

```
                    dc=example,dc=com
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ou=People      ou=Groups      ou=Service
            │              │              │
     ┌──────┼──────┐  ┌───┼────┐    cn=readonly
     │      │      │  │   │    │    cn=ldap-admin
   uid=john uid=jane uid=bob  cn=admins  cn=users
```

### Key LDAP Attributes

```
┌────────────────────────────────────────────────────────┐
│  OBJECTCLASS: inetOrgPerson / posixAccount              │
├────────────────────────────────────────────────────────┤
│  uid              = john                                 │
│  cn               = John Smith                           │
│  sn               = Smith                                │
│  givenName        = John                                 │
│  mail             = john@example.com                     │
│  uidNumber        = 10001                                │
│  gidNumber        = 10000                                │
│  homeDirectory    = /home/john                           │
│  loginShell       = /bin/bash                            │
│  userPassword     = {SSHA}hashed_password               │
│  memberOf         = cn=admins,ou=Groups,dc=example,dc=com│
│  sshPublicKey     = ssh-rsa AAAA... user@example.com     │
│  shadowLastChange = 20265                                │
│  shadowMin        = 7                                    │
│  shadowMax        = 90                                   │
│  shadowWarning    = 14                                   │
└────────────────────────────────────────────────────────┘
```

### Setting Up OpenLDAP Server (Quick Reference)

```bash
# Install OpenLDAP (RHEL/Fedora)
sudo dnf install openldap-servers openldap-clients

# Install OpenLDAP (Debian/Ubuntu)
sudo apt install slapd ldap-utils

# Start and enable
sudo systemctl enable --now slapd

# Set admin password
sudo ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: {SSHA}$(slappasswd -s "AdminP@ss123")
EOF
```

```bash
# Import basic schemas
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
```

```bash
# Create base DN
cat <<EOF | sudo ldapadd -Y EXTERNAL -H ldapi:/// 
dn: dc=example,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: Example Organization
dc: example

dn: ou=People,dc=example,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=example,dc=com
objectClass: organizationalUnit
ou: Groups
EOF
```

### LDAP over TLS (ldaps://)

```bash
# Generate certificate (or use Let's Encrypt)
sudo openssl req -new -x509 -nodes -days 365 \
  -keyout /etc/openldap/certs/ldap.key \
  -out /etc/openldap/certs/ldap.crt \
  -subj "/CN=ldap.example.com"

# Configure slapd to use TLS
cat <<EOF | sudo ldapmodify -Y EXTERNAL -H ldapi:///
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/openldap/certs/ca.crt
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/ldap.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/ldap.key
EOF

# Enable ldaps:// in /etc/sysconfig/slapd
sudo sed -i 's|SLAPD_URLS="ldapi:/// ldap:///"|SLAPD_URLS="ldapi:/// ldaps:///"|' /etc/sysconfig/slapd
sudo systemctl restart slapd
```

### Adding Users to LDAP

```bash
# Add a user (using LDIF)
cat <<EOF | sudo ldapadd -x -D "cn=admin,dc=example,dc=com" -W
dn: uid=john,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: john
cn: John Smith
sn: Smith
givenName: John
mail: john@example.com
uidNumber: 10001
gidNumber: 10000
homeDirectory: /home/john
loginShell: /bin/bash
userPassword: {SSHA}$(slappasswd -s "temp123")
shadowLastChange: 0
shadowMin: 7
shadowMax: 90
shadowWarning: 14
EOF
```

> 🔍 **Reverse Engineering Insight:** When SSSD queries LDAP, it doesn't use `ldapsearch` — it uses the `libldap` C library directly. The LDAP filter it generates depends on `ldap_user_object_class` and `ldap_user_name` in `sssd.conf`. If these are wrong, you'll see zero results even though LDAP itself works fine.

---

## 7. authselect — Managing PAM Profiles

### What is authselect?

`authselect` is the modern replacement for `authconfig` (RHEL 8+/Fedora 28+). It manages PAM and NSS configuration as complete profiles, preventing manual edits from breaking the system.

```
┌──────────────────────────────────────────────────────────┐
│                    BEFORE (authconfig)                     │
│  Manual /etc/pam.d/ edits → fragile, overwritten          │
│  authconfig --enableldapauth → sometimes broke things     │
├──────────────────────────────────────────────────────────┤
│                    NOW (authselect)                        │
│  Predefined profiles → predictable, safe                  │
│  Custom features → extend without replacing               │
│  Backup/restore → safe rollback                           │
└──────────────────────────────────────────────────────────┘
```

### Available Profiles

```bash
# List available profiles
authselect list

# Typical output:
# sssd                  - Local users only with SSSD cache (default for SSSD)
# winbind               - Winbind domain member
# none                  - No configuration management

# Show what a profile includes
authselect show sssd
```

```bash
# Profile contents:
authselect show sssd

# Output:
# /etc/pam.d/system-auth:
#   auth        required      pam_env.so
#   auth        required      pam_faillock.so preauth silent
#   auth        sufficient    pam_unix.so nullok try_first_pass
#   auth        [default=die] pam_faillock.so authfail
#   auth        sufficient    pam_sss.so forward_pass
#   auth        required      pam_deny.so
#   ...
#
# /etc/pam.d/password-auth:
#   (similar structure for network logins)
#
# /etc/nsswitch.conf:
#   passwd:     sss files
#   shadow:     sss files
#   group:      sss files
```

### Selecting a Profile

```bash
# Select the SSSD profile (for LDAP/AD integration)
sudo authselect select sssd

# With force (overwrites existing config)
sudo authselect select sssd --force

# Backup first (recommended)
sudo authselect select sssd --backup=/root/pam-backup-$(date +%Y%m%d)
```

### Using Features (Customization)

Instead of editing PAM files, you enable/disable features:

```bash
# List available features
authselect list-features sssd

# Typical features:
# with-silent-lastlog    - Silence lastlog/spoofing messages
# with-faillock          - Enable pam_faillock for brute-force protection
# with-mkhomedir         - Auto-create home directories on first login
# with-sssd              - Enable SSSD (usually on by default in sssd profile)
# with-pamaccess         - Enable pam_access for access control
# with-pamtempfiles      - Enable pam_tempfiles

# Enable features
sudo authselect enable-feature with-faillock
sudo authselect enable-feature with-mkhomedir

# Enable multiple features at once
sudo authselect enable-feature with-faillock with-mkhomedir

# Disable a feature
sudo authselect disable-feature with-faillock

# Apply changes (after enabling/disabling features)
sudo authselect apply-changes
```

```bash
# One-command select with features
sudo authselect select sssd with-faillock with-mkhomedir --force
```

### Custom Profiles

```bash
# Create a custom profile based on sssd
sudo authselect create-profile my-profile -b sssd --symlink-pam --symlink-nsswitch

# This creates:
# /etc/authselect/custom/my-profile/
# ├── system-auth       (symlinked to base)
# ├── password-auth     (symlinked to base)
# ├── fingerprint-auth  (symlinked to base)
# ├── smartcard-auth    (symlinked to base)
# ├── postlogin         (symlinked to base)
# ├── nsswitch.conf     (symlinked to base)
# └── password          (symlinked to base)

# Now you can customize without affecting the base profile
# Edit /etc/authselect/custom/my-profile/system-auth
# Then apply:
sudo authselect select custom/my-profile
```

### Backup and Restore

```bash
# Backup current state
sudo authselect backup /root/pam-backup-20260726

# List available backups
sudo authselect list-backups

# Restore from backup
sudo authselect restore /root/pam-backup-20260726

# Remove old backup
sudo authselect remove-backup /root/pam-backup-20260726
```

> ⚠️ **Warning:** If you have manually edited `/etc/pam.d/` files, running `authselect select` will overwrite your changes. Always create a backup first. If you need custom PAM settings, create a custom profile.

---

## 8. Centralized Auth in Practice

### Complete Workflow: Join a FreeIPA Domain

```bash
# Step 1: Install required packages (RHEL/Fedora)
sudo dnf install -y freeipa-client sssd oddjob oddjob-mkhomedir

# Step 2: Install required packages (Debian/Ubuntu)
sudo apt install -y freeipa-client sssd-tools oddjob-mkhomedir

# Step 3: Verify DNS resolution (critical!)
nslookup $(hostname -d)
nslookup _ldap._tcp.example.com

# Step 4: Join the domain
sudo ipa-client-install \
  --domain=example.com \
  --server=ipa.example.com \
  --realm=EXAMPLE.COM \
  --mkhomedir \
  --enable-dns-updates \
  -p admin \
  -w 'AdminP@ss123'

# Step 5: Verify the join
sudo ipa-client-install --uninstall  # if you need to redo
sudo kinit admin                      # test Kerberos
sudo ipa host-show $(hostname)        # verify host registration
```

```bash
# Step 6: Verify SSSD is running
sudo systemctl status sssd
sudo sssctl domain-status example.com

# Step 7: Test user lookup
getent passwd <ipa-user>
id <ipa-user>
sudo su - <ipa-user>

# Step 8: Test authentication
ssh <ipa-user>@localhost
```

### Joining Active Directory (without FreeIPA)

```bash
# Install packages
sudo dnf install -y realmd sssd adcli samba-common-tools

# Discover the domain
sudo realm discover example.com

# Join (requires domain admin credentials)
sudo realm join --user=administrator example.com

# Verify
sudo realm list
realm leave example.com  # to undo

# Check SSSD config after join
cat /etc/sssd/sssd.conf
# realm join creates this automatically with correct LDAP/Kerberos settings
```

### Troubleshooting SSSD

```bash
# Increase debug level
# Edit /etc/sssd/sssd.conf
debug_level = 9

# Restart SSSD
sudo systemctl restart sssd

# Watch the logs in real-time
sudo tail -f /var/log/sssd/sssd_example.com.log
sudo tail -f /var/log/sssd/sssd_nss.log
sudo tail -f /var/log/sssd/sssd_pam.log

# Clear SSSD cache completely
sudo sss_cache -E
sudo systemctl restart sssd

# Check for SSSD-related issues
sudo sssctl analyze           # SSSD analyze tool (RHEL 8+)
sudo sssctl domain-status example.com

# Common issues and fixes:
# 1. "No such user" → check ldap_user_search_base, ldap_user_object_class
# 2. "Authentication failed" → check auth_provider, ldap_default_bind_dn
# 3. "Access denied" → check access_provider settings
# 4. "Trust refused" → check realm/domain join, time sync (chrony)
# 5. Slow logins → check entry_cache_timeout, ldap_uri (DNS round-robin?)
```

```bash
# Debug a specific user
sudo sssctl user-status <username>

# Test LDAP connectivity directly
ldapsearch -x -H ldaps://ldap.example.com \
  -b "ou=People,dc=example,dc=com" \
  -D "cn=readonly,ou=Service,dc=example,dc=com" \
  -W "(uid=john)"

# Check NSS configuration
getent passwd   # should show local + LDAP users
getent group    # should show local + LDAP groups
```

### Debug Logs Location

```bash
# SSSD log files
/var/log/sssd/
├── sssd.log              # Monitor process log
├── sssd_example.com.log  # Domain-specific log
├── sssd_nss.log          # NSS responder log
├── sssd_pam.log          # PAM responder log
└── sssd_ssh.log          # SSH responder log

# PAM logs (authentication attempts)
journalctl -u sshd        # SSH auth attempts
/var/log/secure            # RHEL (if rsyslog configured)
/var/log/auth.log          # Debian/Ubuntu

# Enable detailed PAM logging
# Add to /etc/pam.d/sshd or system-auth:
auth optional pam_logind.so
```

> 🔍 **Reverse Engineering Insight:** When SSSD joins a domain, it creates a machine account in LDAP/AD. This account has a Kerberos keytab stored in `/etc/sss/sssd.keytab`. If this keytab is lost or corrupted, SSSD cannot authenticate against the directory server. You can regenerate it with `adcli update --computer-password-lifetime=0` (AD) or re-joining the domain.

---

## 9. PAM Security

### Brute Force Protection

```bash
# Using pam_faillock (modern approach)
auth    required    pam_faillock.so preauth silent audit deny=5 unlock_time=900 fail_interval=900
auth    [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900 fail_interval=900

# deny=5           → lock after 5 failures
# unlock_time=900  → auto-unlock after 15 minutes
# fail_interval=900 → count failures within 15-minute window
# audit             → log username to syslog (for forensics)

# Manual lockout check
sudo faillock --user john
# Output: john: Failune COUNT: 3, UNLOCK_TIME: 1721930400

# Manual unlock
sudo faillock --user john --reset
```

### Account Enumeration Prevention

```bash
# PAM's "required" control flag delays failure messages
# This prevents timing attacks to enumerate valid usernames

# GOOD: Using "required" (delayed failure)
auth    required    pam_unix.so

# BAD: Using "requisite" (immediate failure reveals username validity)
auth    requisite   pam_unix.so

# Enumeration-safe pattern:
auth    required    pam_faillock.so preauth silent audit
auth    sufficient  pam_unix.so
auth    [default=die] pam_faillock.so authfail
auth    required    pam_deny.so

# When a non-existent user tries to log in:
# pam_unix.so fails → pam_deny.so denies → same error as wrong password
# No way to tell if the user exists
```

### Privilege Escalation Risks

```bash
# DANGER: pam_permit.so allows anyone to authenticate
auth    sufficient  pam_permit.so    # NEVER use this in auth!

# DANGER: pam_rootok.so lets root bypass everything
auth    sufficient  pam_rootok.so    # Only safe in su/sudo contexts

# DANGER: pam_wheel.so without required
auth    optional    pam_wheel.so     # Doesn't enforce, just allows

# SAFE: pam_wheel.so with required (only wheel members can su)
auth    required    pam_wheel.so use_uid

# DANGER: Wildcard includes
auth    include     *    # Includes ALL files in pam.d/ — chaos

# SAFE: Explicit includes
auth    include     system-auth
```

### PAM Security Best Practices

```bash
# 1. Always end auth stacks with pam_deny.so
auth    required    pam_deny.so     # Catch-all deny

# 2. Use "required" instead of "requisite" for sensitive modules
#    (prevents username enumeration via timing)

# 3. Protect /etc/pam.d/ files
sudo chmod 644 /etc/pam.d/*
sudo chown root:root /etc/pam.d/*

# 4. Protect /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf

# 5. Audit PAM changes
sudo auditctl -w /etc/pam.d/ -p wa -k pam_config
sudo auditctl -w /etc/sssd/ -p wa -k sssd_config

# 6. Use authselect to prevent accidental breaks
sudo authselect select sssd with-faillock

# 7. Monitor failed logins
sudo journalctl -u sshd | grep -i "failed\|invalid"
sudo lastb | head -20    # List failed login attempts

# 8. Implement account lockout that actually locks
#    unlock_time=0 means PERMANENT lockout (admin must reset)
auth required pam_faillock.so deny=5 unlock_time=0
```

> ⚠️ **Warning:** A misconfigured PAM stack can lock you out of the entire system. Before making PAM changes, always: (1) keep a root shell open, (2) create a backup with `authselect backup`, (3) test with `su - testuser` before closing the root shell.

---

## 🖐️ Hands-On Practices

### Practice 1: Read and Understand Your PAM Stack

```bash
# View the PAM configuration for SSH
cat /etc/pam.d/sshd

# View the PAM configuration for login
cat /etc/pam.d/login

# Compare them — what modules are different?
diff /etc/pam.d/sshd /etc/pam.d/login

# Find all PAM modules loaded on your system
find /usr/lib64/security/ -name "pam_*.so" | sort

# On Debian/Ubuntu:
find /lib/security/ -name "pam_*.so" | sort
```

✅ **Expected**: You can identify the auth, account, password, and session lines in each config, and see which modules are shared

### Practice 2: Trace a Login Through PAM

```bash
# Add debug logging to PAM
# Edit /etc/pam.d/su and add "debug" to pam_unix.so line:
# auth  required  pam_unix.so debug

# Monitor PAM debug output
sudo journalctl -f &

# In another terminal, try to su to a user
su - testuser
# Enter wrong password, then correct password

# Check the logs for PAM module messages
sudo journalctl | grep pam_ | tail -20

# Remove debug when done
```

✅ **Expected**: You see detailed PAM module output including password verification steps

### Practice 3: Test pam_faillock

```bash
# Enable faillock with authselect
sudo authselect enable-feature with-faillock
sudo authselect apply-changes

# Check current faillock status
sudo faillock --user testuser

# Attempt 5 wrong passwords
for i in $(seq 1 6); do
  echo "Attempt $i:"
  su -c "echo 'wrong'" testuser 2>&1 || true
done

# Check lockout status
sudo faillock --user testuser

# Reset the lockout
sudo faillock --user testuser --reset

# Verify unlocked
sudo faillock --user testuser
```

✅ **Expected**: After 5 failed attempts, the account is locked; `faillock --reset` clears it

### Practice 4: Configure Password Quality

```bash
# Set password policy
cat <<EOF | sudo tee /etc/security/pwquality.conf
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
maxrepeat = 3
maxclassrepeat = 4
dictcheck = 1
usercheck = 1
retry = 3
EOF

# Test the policy
passwd testuser
# Try "password" → should fail
# Try "Str0ng!Pass#2026" → should succeed

# View current password aging
sudo chage -l testuser
```

✅ **Expected**: Weak passwords are rejected; policy matches your pwquality.conf settings

### Practice 5: Explore SSSD Status

```bash
# Check SSSD service status
sudo systemctl status sssd

# List configured domains
sudo sssctl domain-status example.com

# Check SSSD configuration
sudo cat /etc/sssd/sssd.conf

# View SSSD cache
sudo sss_cache -E     # Expire cache
sudo ldbsearch -H /var/lib/sss/db/config.ldb | head -50

# Check what NSS uses
getent passwd | grep sss
getent passwd | grep files
```

✅ **Expected**: You can see SSSD is running, domain status, and NSS configuration showing `sss` before `files`

### Practice 6: LDAP Connectivity Test

```bash
# Test LDAP server connectivity
ldapsearch -x -H ldaps://ldap.example.com \
  -b "dc=example,dc=com" \
  -D "cn=readonly,ou=Service,dc=example,dc=com" \
  -W \
  "(objectClass=posixAccount)" \
  uid uidNumber homeDirectory

# Check TLS certificate
openssl s_client -connect ldap.example.com:636 -showcerts

# Test with ldapwhoami
ldapwhoami -x -H ldaps://ldap.example.com \
  -D "cn=readonly,ou=Service,dc=example,dc=com" \
  -W
```

✅ **Expected**: LDAP search returns user entries; TLS certificate is valid; ldapwhoami returns the bind DN

### Practice 7: Use authselect Safely

```bash
# View current profile
authselect current

# Create a backup
sudo authselect backup /root/pam-before-changes

# List available profiles
authselect list

# Switch to SSSD profile
sudo authselect select sssd --force

# Enable features
sudo authselect enable-feature with-faillock
sudo authselect enable-feature with-mkhomedir

# Verify changes were applied
diff <(cat /etc/pam.d/system-auth) <(authselect list | grep system-auth)

# Restore if needed
sudo authselect restore /root/pam-before-changes
```

✅ **Expected**: You can switch profiles, enable features, and restore backups cleanly

### Practice 8: Custom PAM Profile

```bash
# Create a custom profile
sudo authselect create-profile hardened \
  -b sssd \
  --symlink-pam \
  --symlink-nsswitch

# View the custom profile
ls -la /etc/authselect/custom/hardened/

# Edit system-auth to add custom requirements
sudo vi /etc/authselect/custom/hardened/system-auth
# Add: auth required pam_faillock.so deny=3 unlock_time=600

# Apply the custom profile
sudo authselect select custom/hardened --force

# Verify it's active
authselect current
```

✅ **Expected**: Custom profile is created, selected, and active with your modifications

### Practice 9: Debug SSSD Authentication

```bash
# Enable maximum debug logging
sudo sed -i 's/debug_level = .*/debug_level = 9/' /etc/sssd/sssd.conf
sudo systemctl restart sssd

# Clear cache
sudo sss_cache -E

# Try to authenticate
su - ldapuser

# Check debug logs
sudo tail -100 /var/log/sssd/sssd_example.com.log
sudo tail -50 /var/log/sssd/sssd_pam.log

# Search for errors
sudo grep -i "error\|fail\|denied" /var/log/sssd/sssd_example.com.log | tail -20

# Reset debug level
sudo sed -i 's/debug_level = 9/debug_level = 3/' /etc/sssd/sssd.conf
sudo systemctl restart sssd
```

✅ **Expected**: Debug logs show the full authentication flow including LDAP queries, cache operations, and result codes

### Practice 10: Manage User Password Aging

```bash
# Set password aging for a user
sudo chage -M 60 -m 7 -W 14 -I 14 testuser

# Verify settings
sudo chage -l testuser

# Force password change on next login
sudo chage -d 0 testuser

# View /etc/shadow entry (password fields)
sudo getent shadow testuser

# Set global defaults
grep -E "^PASS_" /etc/login.defs
```

✅ **Expected**: Password aging is configured; `chage -l` shows correct expiry dates

### Practice 11: pam_google_authenticator Setup

```bash
# Install (RHEL)
sudo dnf install google-authenticator

# Add to PAM for SSH
# Edit /etc/pam.d/sshd, add at the top:
# auth required pam_google_authenticator.so

# Enable in sshd_config
sudo sed -i 's/#ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM yes\nAuthenticationMethods publickey,keyboard-interactive/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Set up as regular user
su - testuser
google-authenticator
# Answer the prompts (scan QR code, save backup codes)

# Test: SSH should ask for verification code after key auth
```

✅ **Expected**: SSH login requires both SSH key AND TOTP verification code

### Practice 12: Audit PAM Configuration Changes

```bash
# Set up audit rules for PAM files
sudo auditctl -w /etc/pam.d/ -p wa -k pam_config_change
sudo auditctl -w /etc/sssd/sssd.conf -p wa -k sssd_config_change

# Make a change (create a test backup)
sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.bak

# Search audit log
sudo ausearch -k pam_config_change -ts recent

# Remove test backup
sudo rm /etc/pam.d/sshd.bak
sudo ausearch -k pam_config_change -ts recent
```

✅ **Expected**: Audit log captures all modifications to PAM configuration files

### Practice 13: Centralized User Verification

```bash
# Test user lookup from multiple sources
echo "=== NSS Sources ==="
getent passwd john     # Should come from SSSD (LDAP) or files
getent group admins    # Should come from SSSD

echo "=== PAM Sources ==="
su - john -c "whoami && id && echo 'PAM auth works'"

echo "=== SSH Key from LDAP ==="
sudo ssh ldapuser@localhost "echo 'LDAP SSH key auth works'"

echo "=== Home Directory ==="
ls -la /home/john/     # Should exist (with mkhomedir feature)

echo "=== Sudo from LDAP ==="
sudo -l -U john        # Should show LDAP-defined sudo rules
```

✅ **Expected**: All lookups come from centralized LDAP, not local files

### Practice 14: PAM Session Tracking

```bash
# Add session logging to PAM
# Edit /etc/pam.d/sshd, add:
# session optional pam_exec.so /usr/local/bin/log_session.sh

# Create the logging script
sudo cat <<'SCRIPT' > /usr/local/bin/log_session.sh
#!/bin/bash
echo "$(date) | USER=$PAM_USER | SERVICE=$PAM_SERVICE | TYPE=$PAM_TYPE | TTY=$PAM_TTY" >> /var/log/pam_sessions.log
SCRIPT
sudo chmod 755 /usr/local/bin/log_session.sh

# Test by SSHing in
ssh testuser@localhost "exit"

# Check the log
cat /var/log/pam_sessions.log
```

✅ **Expected**: Session open/close events are logged with user, service, and timestamp

### Practice 15: Complete PAM Security Audit

```bash
#!/bin/bash
# pam_audit.sh — Security audit of PAM configuration
echo "=== PAM Security Audit ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Faillock status for locked accounts:"
sudo faillock --user 2>/dev/null | head -10 || echo "  (pam_faillock not configured)"
echo ""

echo "2. Password policy:"
grep -E "^PASS_" /etc/login.defs
echo ""

echo "3. PAM config file permissions:"
ls -la /etc/pam.d/ | head -10
echo ""

echo "4. SSSD config permissions:"
ls -la /etc/sssd/sssd.conf
echo ""

echo "5. Accounts with no password (security risk):"
sudo awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow
echo ""

echo "6. Accounts with UID 0 (root-level):"
awk -F: '$3 == 0 {print $1}' /etc/passwd
echo ""

echo "7. Recently failed logins:"
sudo lastb 2>/dev/null | head -10
echo ""

echo "8. Active PAM modules:"
ls /usr/lib64/security/pam_*.so 2>/dev/null | wc -l
echo ""

echo "9. Current authselect profile:"
authselect current 2>/dev/null || echo "  (authselect not available)"
echo ""

echo "10. Audit rules for PAM:"
sudo auditctl -l 2>/dev/null | grep -i "pam\|sssd" || echo "  (no PAM audit rules)"
```

✅ **Expected**: Complete security audit showing PAM configuration, password policies, and potential vulnerabilities

---

## Deep Understanding

### How the PAM Stack Actually Resolves

The key insight is that PAM processes control flags in a specific way:

```
auth  required   pam_a.so       → passes:  continue
auth  required   pam_b.so       → fails:   continue (but mark failure)
auth  sufficient pam_c.so       → skipped: (prior required failed)
auth  required   pam_d.so       → passes:  continue
auth  required   pam_deny.so    → always fails

RESULT: FAILURE (pam_b.so failed, "required" tracks the failure)
        Even though pam_a.so, pam_c.so, pam_d.so passed

KEY RULE: "sufficient" is only effective if NO prior "required" has failed.
```

```
auth  required   pam_a.so       → passes:  continue
auth  sufficient pam_b.so       → passes:  RETURN SUCCESS immediately
                                     (no prior required failed)
auth  required   pam_c.so       → never reached
auth  required   pam_deny.so    → never reached

RESULT: SUCCESS (pam_b.so succeeded as sufficient)
```

### The Complete Authentication Timeline

```
┌──────────────────────────────────────────────────────────┐
│  t=0ms    User enters username at login prompt            │
│  t=0ms    login process calls pam_authenticate("login")   │
│  t=1ms    PAM reads /etc/pam.d/login                      │
│  t=1ms    PAM loads pam_env.so → sets env variables        │
│  t=2ms    PAM loads pam_faillock.so preauth → checks lock  │
│  t=3ms    Account NOT locked → continue                    │
│  t=3ms    PAM loads pam_unix.so → prompts for password     │
│  t=5000ms User enters password                             │
│  t=5001ms pam_unix.so checks /etc/shadow → success/fail    │
│  t=5002ms If fail: pam_faillock.so authfail → increments   │
│  t=5003ms If fail: pam_deny.so → DENIED                   │
│  t=5003ms If success: pam_sss.so → forward to SSSD        │
│  t=5100ms SSSD checks cache → hit? return immediately     │
│  t=5100ms SSSD checks LDAP → queries server               │
│  t=5200ms LDAP returns success → SSSD returns to PAM      │
│  t=5201ms All required modules passed → AUTH GRANTED        │
│  t=5202ms pam_account checking → pam_unix, pam_sss         │
│  t=5203ms Account is valid → proceed                       │
│  t=5204ms pam_session setup → pam_limits, pam_namespace    │
│  t=5205ms Home directory created (pam_mkhomedir)           │
│  t=5206ms Shell launched                                   │
│  TOTAL: ~5.2 seconds (mostly user typing time)             │
└──────────────────────────────────────────────────────────┘
```

### SSSD Response Flow

```
┌─────────────────────────────────────────────────────────────┐
│  PAM request: "Authenticate user=john, password=***"         │
│                      │                                       │
│                      ▼                                       │
│  ┌───────────────────────────────────┐                      │
│  │  SSSD Monitor Process              │                      │
│  │  (receives request)                │                      │
│  └───────────────┬───────────────────┘                      │
│                  │                                            │
│          ┌───────┴────────┐                                  │
│          │                │                                   │
│    ┌─────▼──────┐  ┌─────▼──────────┐                       │
│    │ Cache Hit?  │  │ Cache Miss?     │                      │
│    │             │  │                  │                      │
│    │ Check ldb   │  │ Query LDAP/Kerb │                      │
│    │ database    │  │ Server           │                     │
│    └─────┬──────┘  └─────┬──────────┘                       │
│          │                │                                   │
│    ┌─────▼──────┐  ┌─────▼──────────┐                       │
│    │ Password   │  │ Password        │                      │
│    │ verified   │  │ verified by     │                       │
│    │ from cache │  │ LDAP/Kerb       │                       │
│    └─────┬──────┘  └─────┬──────────┘                       │
│          │                │                                   │
│          └────────┬───────┘                                  │
│                   │                                           │
│          ┌────────▼──────────┐                               │
│          │  Return to PAM:    │                              │
│          │  PAM_SUCCESS or    │                              │
│          │  PAM_AUTH_ERR      │                              │
│          └───────────────────┘                               │
└─────────────────────────────────────────────────────────────┘
```

### authselect vs Manual Editing Decision Tree

```
Need to modify PAM?
         │
         ▼
Does a feature exist for it?
         │
    ┌────┴────┐
    Yes       No
    │         │
    ▼         ▼
  Enable   Create custom profile
  feature  authselect create-profile
    │         │
    ▼         ▼
  authselect  Edit files in
  enable-    /etc/authselect/custom/
  feature    <profile>/
    │         │
    ▼         ▼
  authselect  authselect select
  apply-     custom/<profile>
  changes
```

---

## Command Reference

| Task | Command |
|------|---------|
| List PAM config files | `ls /etc/pam.d/` |
| View PAM config | `cat /etc/pam.d/<service>` |
| Check faillock status | `faillock --user <user>` |
| Reset faillock | `faillock --user <user> --reset` |
| List PAM modules | `find /usr/lib64/security/ -name "pam_*.so"` |
| Set password aging | `chage -M 90 -m 7 -W 14 <user>` |
| View password aging | `chage -l <user>` |
| Force password change | `chage -d 0 <user>` |
| Check password policy | `cat /etc/security/pwquality.conf` |
| SSSD domain status | `sssctl domain-status <domain>` |
| SSSD cache expire | `sss_cache -E` |
| Authselect current | `authselect current` |
| Authselect select profile | `authselect select sssd --force` |
| Authselect enable feature | `authselect enable-feature with-faillock` |
| Authselect backup | `authselect backup /path/backup` |
| Authselect restore | `authselect restore /path/backup` |
| Create custom profile | `authselect create-profile myprofile -b sssd` |
| Test LDAP connectivity | `ldapsearch -x -H ldaps://server -b "dc=ex,dc=com" -D "bind-dn" -W` |
| LDAP whoami | `ldapwhoami -x -H ldaps://server -D "bind-dn" -W` |
| View SSSD debug logs | `tail -f /var/log/sssd/sssd_<domain>.log` |
| Join FreeIPA | `ipa-client-install --domain=... --server=... --realm=...` |
| Join Active Directory | `realm join --user=administrator example.com` |
| Audit PAM changes | `ausearch -k pam_config_change -ts recent` |
| View failed logins | `lastb \| head -20` |
| Check PAM-loaded modules | `cat /proc/<pid>/maps \| grep pam_` |
| SSSD user status | `sssctl user-status <user>` |
| Google Authenticator setup | `google-authenticator` (as target user) |
| PAM session logging | `pam_exec.so /path/to/script.sh` |
| Test PAM manually | `pamtester <service> <user> authenticate` |

---

## What's Coming in Part 66

```
┌─────────────────────────────────────────────────────────┐
│   Part 66: System Hardening — CIS, STIG, and Beyond      │
├─────────────────────────────────────────────────────────┤
│   • CIS Benchmark and STIG hardening standards           │
│   • Automated compliance with OpenSCAP                   │
│   • Kernel hardening via sysctl and sysctl.conf          │
│   • File permission and ownership hardening              │
│   • GRUB and boot security                              │
│   • Secure boot and UEFI                                │
│   • Mandatory Access Control (SELinux/AppArmor)         │
│   • Network hardening (firewall, sysctl networking)     │
│   • Audit framework and compliance reporting            │
│   • Creating a hardening checklist from scratch          │
└─────────────────────────────────────────────────────────┘
```

---

## Self-Test

1. What are the four PAM module types and what does each one handle?
2. What is the difference between `required` and `requisite` control flags?
3. Why does PAM use `required` instead of `requisite` for password checks (hint: enumeration)?
4. What file does PAM read when `sshd` calls `pam_authenticate()`?
5. What is the purpose of `pam_faillock.so` and how does it differ from the deprecated `pam_tally2.so`?
6. What does `try_first_pass` do vs `use_first_pass` in pam_unix?
7. What are the key components of the SSSD architecture (responders and providers)?
8. Why does `/etc/sssd/sssd.conf` need permissions 0600?
9. What is the purpose of `ldap_default_bind_dn` in SSSD configuration?
10. How does SSSD handle offline authentication?
11. What is `authselect` and why did it replace `authconfig`?
12. What does the `with-faillock` feature do when enabled via authselect?
13. What is the danger of using `pam_permit.so` in an auth stack?
14. How do you reset a locked account managed by pam_faillock?
15. What logs should you check when debugging SSSD authentication failures?

**Answers:**
1. auth (identity verification), account (validity checks), password (password changes), session (setup/teardown)
2. `required` continues checking other modules on failure (delays failure message); `requisite` fails immediately
3. Delayed failure prevents attackers from determining whether a username exists (timing attack)
4. `/etc/pam.d/sshd` — the service name passed to `pam_authenticate()` maps to this file
5. pam_faillock tracks and locks accounts after N failures; pam_tally2 was deprecated due to race conditions and lack of audit support
6. `try_first_pass` uses the password from a previous module and re-prompts if it fails; `use_first_pass` uses it without re-prompting
7. Responders: nss, pam, ssh, sudo. Providers: id, auth, access, chpass, sudo, selinux, autofs
8. SSSD refuses to start with less restrictive permissions to protect LDAP/Kerberos credentials stored in the config
9. It is the DN of the service account used to bind (authenticate) to the LDAP directory for queries
10. SSSD caches credentials and user data in an ldb database; when LDAP is unreachable, it falls back to cached data
11. authselect manages PAM/NSS as profiles with predefined features, preventing manual edits that could break authentication
12. It enables pam_faillock for brute-force protection (deny after N attempts, auto-unlock after timeout)
13. pam_permit.so always succeeds, allowing anyone to authenticate without any checks — a critical security hole
14. `sudo faillock --user <username> --reset`
15. `/var/log/sssd/sssd_<domain>.log`, `/var/log/sssd/sssd_pam.log`, `/var/log/secure` or `/var/log/auth.log`, `journalctl -u sshd`

**Score:** 12/15 correct = ready for Part 66.

---

*Linux SysAdmin Course | Part 65 of ∞ | Reverse Engineering Approach*
*Previous → Part 64: Linux Namespaces*
*Next → Part 66: System Hardening*

[← Previous](part64.md) | [Next →](part66.md)