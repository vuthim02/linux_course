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

---



---

[← Previous](14-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](16-summary-command-reference-for-part.md)
