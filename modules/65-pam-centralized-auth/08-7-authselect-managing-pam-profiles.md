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



---

[← Previous](07-6-ldap-integration.md) | [↑ Index](index.md) | [Next →](09-8-centralized-auth-in-practice.md)
