## 🔍 Section 5: /etc/passwd — The User Database (Deep Dive)

This is the oldest user database in Unix. Every user account has one line.

```bash
cat /etc/passwd
```

Each line has 7 fields separated by colons:

```
alice:x:1001:1001:Alice Johnson:/home/alice:/bin/bash
│     │ │     │      │              │           │
│     │ │     │      │              │           └── Shell (what runs on login)
│     │ │     │      │              └────────────── Home directory
│     │ │     │      └───────────────────────────── GECOS (full name, comma-separated)
│     │ │     └──────────────────────────────────── Group ID (GID)
│     │ └────────────────────────────────────────── User ID (UID)
│     └──────────────────────────────────────────── Password placeholder (x = shadow)
└────────────────────────────────────────────────── Username
```

### Field Details

| Field | Example | Meaning |
|-------|---------|---------|
| Username | `alice` | Login name (1-32 chars, no uppercase on some systems) |
| Password | `x` | If `x`, password is in `/etc/shadow`. If `*` or `!`, account is locked |
| UID | `1001` | User ID. 0=root, 1-999=system, 1000+=regular users |
| GID | `1001` | Primary group ID (from `/etc/group`) |
| GECOS | `Alice Johnson` | Full name or description. Comma-separated fields |
| Home | `/home/alice` | User's home directory |
| Shell | `/bin/bash` | Login shell. `/sbin/nologin` or `/bin/false` disables login |

### UID Ranges — The Official Map

```bash
UID 0       → root (superuser)
UID 1-999   → System accounts (daemons, services)
               1 = bin, 2 = daemon, 8 = mail...
UID 1000+   → Regular human users
```

> 🔍 **Reverse Engineering Insight:** Your UID is your true identity. You can change your username, your home directory, your shell — but your UID stays the same. Linux identifies you by UID, not by name.

### Special Accounts You Will See

```bash
root:x:0:0:root:/root:/bin/bash       # All-powerful
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin   # Least-privilege account
```

> 💡 The `nobody` account is used by services that need minimal privileges. If a web server gets hacked while running as `nobody`, the attacker has almost no power.

---



---

[← Previous](07-level-2-intermediary-user-group.md) | [↑ Index](index.md) | [Next →](09-section-6-etcshadow-the-password.md)
