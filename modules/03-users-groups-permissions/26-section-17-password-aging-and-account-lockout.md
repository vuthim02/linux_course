## 🔍 Section 17: Password Aging and Account Lockout

### chage — Password Aging Configuration

```bash
# View password aging for a user
chage -l bob

# Force password change every 90 days
sudo chage -M 90 bob

# Warn user 7 days before password expires
sudo chage -W 7 bob

# Set account to expire on a specific date
sudo chage -E 2025-12-31 bob

# Minimum days between password changes (prevent cycling)
sudo chage -m 1 bob

# Inactive days after expiry before account lock
sudo chage -I 30 bob

# Force password change at next login
sudo chage -d 0 bob
```

### faillock — Account Lockout After Failed Logins

```bash
# RHEL/Fedora: faillock
faillock --user bob            # View failed attempts
sudo faillock --user bob --reset  # Clear lock

# Debian/Ubuntu: pam_tally2
pam_tally2 --user bob          # View failed attempts
sudo pam_tally2 --user bob --reset
```

### Password Quality with pwquality

```bash
# /etc/security/pwquality.conf
# minlen = 12           # Minimum password length
# minclass = 4          # At least one of: upper, lower, digit, special
# maxrepeat = 3         # Max consecutive repeated chars
# difok = 5             # Chars different from old password
# reject_username       # Password cannot contain username

# Test password quality
pwscore                   # Interactive test
echo "MyPass123!" | pwscore
```

### Default Settings

```bash
# /etc/login.defs controls system-wide user defaults
grep -E '^PASS|^UID|^GID|^CREATE' /etc/login.defs

# Key settings:
# PASS_MAX_DAYS   99999   # Password never expires (default)
# PASS_MIN_DAYS   0        # Can change password immediately
# PASS_WARN_AGE   7        # Warn 7 days before expiry
# UID_MIN          1000    # Regular users start at UID 1000
```



[← Previous](25-section-16-linux-capabilities.md) | [↑ Index](index.md) | [Next →](27-section-18-resource-limits-and-groups.md)
