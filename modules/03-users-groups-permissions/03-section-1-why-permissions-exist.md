## 🔍 Section 1: Why Permissions Exist — The Core Problem

Linux was designed from day one as a **multi-user system**. This means many people use the same machine at the same time.

Ask yourself: what stops one user from deleting another user's files? What stops a student from reading the exam answers stored in the professor's folder? What stops a hacked web server from wiping your entire system?

**The answer: permissions.**

Linux has three layers of access control:

```
Layer 1: Standard Permissions (rwx)
  └─ Every file has an owner, group, and "others" permission
  └─ Controls read, write, execute

Layer 2: Special Permissions (SUID, SGID, Sticky Bit)
  └─ Extended controls for special cases
  └─ "Run this file as its owner, not as me"

Layer 3: Access Control Lists (ACLs)
  └─ Fine-grained: "User A can read, User B can write"
  └─ Everyone else gets nothing
```

Most courses stop at Layer 1. A real sysadmin needs all three.





[← Previous](02-level-1-basic-permission-fundamentals.md) | [↑ Index](index.md) | [Next →](04-section-2-reading-permission-strings.md)
