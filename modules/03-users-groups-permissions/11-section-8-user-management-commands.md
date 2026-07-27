## 🔍 Section 8: User Management Commands

### useradd — Create a User

```bash
# Simplest form (uses defaults)
sudo useradd bob

# With all options specified
sudo useradd -u 1050 -g developers -G sudo,docker -c "Bob Smith" -m -s /bin/bash bob

# What each flag means:
# -u 1050        → UID 1050
# -g developers  → Primary group
# -G sudo,docker → Supplementary groups
# -c "Bob Smith" → Full name (GECOS)
# -m             → Create home directory (/home/bob)
# -s /bin/bash   → Login shell
```

### Defaults for useradd

```bash
# See all defaults the system uses
useradd -D
# Output:
# GROUP=100       ← Default group if -g not specified
# HOME=/home       ← Home directory prefix
# INACTIVE=-1      ← Password expiry disabled
# EXPIRE=          ← No account expiry
# SHELL=/bin/bash  ← Default shell
# SKEL=/etc/skel   ← Template for home directory
# CREATE_MAIL_SPOOL=yes
```

### The SKEL Directory — Every New Home Comes From Here

```bash
ls -la /etc/skel/
# .bashrc  .profile  .bash_logout  ...
```

When `useradd -m` creates a home directory, it copies everything from `/etc/skel/`. This is why every new user gets the same default configuration files.

```bash
# Add a company-wide welcome message to all NEW users
echo "echo 'Welcome to the company!'" | sudo tee -a /etc/skel/.profile
```

### usermod — Modify a User

```bash
# Change username
sudo usermod -l newname oldname
# Note: also rename the home directory manually

# Change UID
sudo usermod -u 1055 bob

# Change primary group
sudo usermod -g developers bob

# Add to supplementary groups (APPEND, don't replace)
sudo usermod -aG sudo bob
# ⚠️ Without -a, usermod -G REPLACES all groups. Always use -a with -G.

# Lock a user account
sudo usermod -L bob     # Adds ! to shadow

# Unlock
sudo usermod -U bob     # Removes ! from shadow

# Change home directory
sudo usermod -d /new/home/bob -m bob
# -m moves contents from old home to new home

# Set account expiry
sudo usermod -e 2025-12-31 bob
# After this date, account cannot be used

# Change shell (prevent login)
sudo usermod -s /sbin/nologin bob

# Change full name
sudo usermod -c "Bob Smith (Contractor)" bob
```

### userdel — Delete a User

```bash
# Remove user but leave home directory
sudo userdel bob

# Remove user AND home directory, mail spool
sudo userdel -r bob

# Force delete (even if still logged in)
sudo userdel -f bob
```

> 🚨 **Warning:** Never delete a user whose UID still owns files. The files become orphaned (shown as numeric UID in `ls -l`). Always find and reassign files first:
> ```bash
> find / -user bob -type f 2>/dev/null
> ```

### passwd — Manage Passwords

```bash
# Change your own password
passwd

# Change another user's password (root only)
sudo passwd bob

# Lock a password
sudo passwd -l bob

# Unlock
sudo passwd -u bob

# Force password change on next login
sudo passwd -e bob
# This sets the "last changed" field to 0

# Delete a password (no password login — careful!)
sudo passwd -d bob

# Check password status
sudo passwd -S bob
# bob P 2024-01-15 0 99999 7 -1
# (P=usable, L=locked, NP=no password)
```

---



---

[← Previous](10-section-7-etcgroup-group-database.md) | [↑ Index](index.md) | [Next →](12-section-9-group-management-commands.md)
