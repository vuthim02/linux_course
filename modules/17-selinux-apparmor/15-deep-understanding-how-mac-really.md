## 🧠 Deep Understanding — How MAC Really Works

### SELinux Type Enforcement

The core of SELinux is a set of rules:

```
allow SOURCE_TYPE TARGET_TYPE:CLASS { PERMISSIONS };
```

Example:
```
allow httpd_t shadow_t:file { read };
```

This means: "A process with type httpd_t is ALLOWED to read a file with type shadow_t."

By default, **everything is denied**. Policy files explicitly allow specific operations.

### The SELinux Policy Database

```bash
# The compiled policy is stored in:
ls /etc/selinux/targeted/policy/

# The source policy (if installed) is in:
ls /etc/selinux/targeted/src/

# Policy modules (custom additions)
ls /etc/selinux/targeted/modules/active/modules/

# Current loaded modules
sudo semodule -l | head -20
```

### AppArmor Path-Based Enforcement

AppArmor doesn't label files. It uses file system paths:

```
Rule: /etc/shadow r,
Allows: Reading /etc/shadow

Rule: /etc/shadow w,
Allows: Writing /etc/shadow

No rule for /etc/shadow = DENIED
```

### SELinux Users and Roles

SELinux has its own user system, separate from Linux users:

```bash
# Map Linux users to SELinux users
semanage login -l

# Default mapping:
# Linux user → SELinux user
# root       → unconfined_u (root is NOT confined by default)
# __default__→ unconfined_u (regular users are not confined)

# To confine specific users:
semanage login -a -s user_u username
```

**Roles** bridge users and types:
- `user_r` — regular user, can only run `user_t` domain
- `staff_r` — staff, can run `staff_t` and switch to `sysadm_r`
- `sysadm_r` — system admin, can run `sysadm_t` domain
- `system_r` — system processes (daemons)

```bash
# List SELinux users and their allowed roles:
semanage user -l

# Create a custom SELinux user:
semanage user -a -R "staff_r sysadm_r" myadmin_u
```

### MLS and MCS: Sensitivity and Categories

Multi-Level Security adds an extra field to the context: `user:role:type:sensitivity[:category]`

```
Example MLS context:
  system_u:object_r:shadow_t:s0          # Level s0 (lowest)
  system_u:object_r:secret_t:s2          # Level s2 (higher)
  user_u:user_r:user_t:s0-s0:c0.c1023    # Range: s0-s0, categories 0-1023
```

```bash
# Check if MLS/MCS is active:
sestatus | grep "Policy MLS status"

# Set categories on a file:
chcat +c12 /path/to/file

# List categories:
chcat -L

# Run a shell with reduced clearance:
runcon -l s0:c0,c1 sh
id -Z   # Shows restricted context

# The "no read up, no write down" rule:
# A process at s0 can read s0 files only
# A process at s1 can read s0 and s1 files
# A process at s1 can write to s1 files only (no write down)
```

MLS (multi-level) uses ordered sensitivity levels. MCS (multi-category) uses unordered categories — simpler for cloud/multi-tenant isolation.





[← Previous](14-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](16-summary-command-reference-for-part.md)
