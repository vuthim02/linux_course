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



---

[← Previous](04-3-pam-modules-deep-dive.md) | [↑ Index](index.md) | [Next →](06-5-sssd-architecture.md)
