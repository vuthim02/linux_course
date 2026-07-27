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



---

[← Previous](09-8-centralized-auth-in-practice.md) | [↑ Index](index.md) | [Next →](11-hands-on-practices.md)
