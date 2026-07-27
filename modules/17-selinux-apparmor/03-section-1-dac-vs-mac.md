## 🔍 Section 1: DAC vs MAC

### Discretionary Access Control (DAC)

What you already know:

```
File: /etc/shadow
Owner: root
Group: shadow
Permissions: -rw-r-----

The owner (root) can change permissions.
The owner decides who accesses the file.
This is "DISCRETIONARY" — the owner has discretion.
```

### Mandatory Access Control (MAC)

What SELinux/AppArmor add:

```
Even if DAC says "yes" (e.g., file is world-readable),
MAC can say "NO" because:
- The process doesn't have the right security context
- The process isn't allowed to access that type of file
- The process is confined by a profile

This is "MANDATORY" — even root cannot override it.
```

### Why MAC Matters

```
Scenario: A web server (nginx) has a vulnerability.
Attacker exploits it to get a shell as www-data.

DAC only: Attacker reads /etc/shadow (if permissions allow).
           Attacker reads all files www-data can access.
DAC + MAC: SELinux says "nginx is a web server, not allowed
           to read shadow files." Blocked even though
           DAC permissions say yes.
```

### SELinux vs AppArmor

| Feature | SELinux | AppArmor |
|---------|---------|----------|
| Origin | Red Hat / NSA | Canonical / SUSE |
| Labels | Every file, process, port, device | Programs have profiles |
| Policy type | Type Enforcement (TE) | Path-based profiles |
| Granularity | Very fine (everything labeled) | File path patterns |
| Complexity | Higher | Lower |
| Learning curve | Steeper | Gentler |

| Distribution | Default |
|---|---|
| Fedora / RHEL / CentOS | SELinux (enforcing) |
| Debian / Ubuntu | AppArmor (enforcing) |
| openSUSE | AppArmor |
| Arch Linux | None (user chooses) |

---



---

[← Previous](02-level-1-basic-understanding-mac.md) | [↑ Index](index.md) | [Next →](04-section-2-selinux-modes-and.md)
