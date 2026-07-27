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



---

[← Previous](03-2-pam-configuration-etcpamd.md) | [↑ Index](index.md) | [Next →](05-4-password-policies.md)
