## 🧠 Deep Understanding — How Permissions Really Work

### The Real Identity Check

When a process tries to access a file, Linux performs this check:

```
Is the process running as UID 0 (root)?
  ├── YES → Permission GRANTED (root can do anything)
  └── NO →
      Is the process UID the same as the file owner?
        ├── YES → Apply USER permission bits
        └── NO →
            Is the process GID (or any supplementary GID) in the file's group?
              ├── YES → Apply GROUP permission bits
              └── NO → Apply OTHER permission bits
```

It stops at the **first** match. If you are the owner, group permissions are **ignored** entirely.

> 💡 **Real implication:** If owner has `r--` and group has `rwx`, the owner cannot write to the file even though their group can. The owner match was found first.

### The inode — Where Permissions Live

Permissions are stored in the **inode**, not in the filename. This is why:
- Hard links cannot have different permissions — they share the same inode
- Moving a file (same filesystem) preserves permissions — the inode didn't change
- Renaming a file preserves permissions — the inode didn't change

```bash
# Check inode number and see permissions live there
ls -li /etc/hosts
# 1234567 -rw-r--r-- 1 root root 221 ...
# ↑
# inode number

# Two names for the same inode have the same permissions
ln /etc/hosts /tmp/hosts_copy
ls -li /etc/hosts /tmp/hosts_copy
# Same inode = same permissions
```

### Why sudo Doesn't Need Passwords Sometimes

Look at `/etc/sudoers.d/`:

```bash
ls -la /etc/sudoers.d/
```

Some distros put a file like `90-cloud-init-users` that grants passwordless sudo to the first user. This is why your admin user can run sudo without a password.

### The Security Triad

Every permission decision balances three things:

```
Confidentiality ─── Who can READ this?
     ↑
Integrity     ─── Who can WRITE this?
     ↑
Availability  ─── Who can EXECUTE/ACCESS this?
```

As a sysadmin, every file you create should make you ask: "Who should read this? Who should change this? Who should run this?"

---



---

[← Previous](19-practice-section-20-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](21-summary-complete-command-reference-for.md)
