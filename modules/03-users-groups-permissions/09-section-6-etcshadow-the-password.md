## 🔍 Section 6: /etc/shadow — The Password File (Sensitive!)

```bash
sudo cat /etc/shadow
```

This file is only readable by root. Each line corresponds to `/etc/passwd`:

```
alice:$6$xyz123$abc...def:19876:0:99999:7:30::
│      │                      │     │   │   │ ││
│      │                      │     │   │   │ │└─ Unused (reserved)
│      │                      │     │   │   │ └── Account expiration days
│      │                      │     │   │   └──── Warning days before password expires
│      │                      │     │   └──────── Maximum password age (days)
│      │                      │     └──────────── Minimum password age (days)
│      │                      └────────────────── Last password change (days since epoch)
│      └───────────────────────────────────────── Hashed password
└───────────────────────────────────────────────── Username
```

### Password Hash Format

```
$type$salt$hash
$6$xyz123$abc...def
```

| Type | Hash Algorithm |
|------|---------------|
| `$1$` | MD5 (weak, avoid) |
| `$2y$` | Blowfish |
| `$5$` | SHA-256 |
| `$6$` | SHA-512 (current standard) |
| `$y$` | Yescrypt (newer, on some distros) |

### Shadow Flags

| Value | Meaning |
|-------|---------|
| `*` | Account is locked. No login possible. |
| `!` | Password is locked. May have been set then locked. |
| `!!` | No password set. User cannot log in with password. |
| Empty | No password. User cannot log in (on modern systems). |

> 💡 **Practical note:** To lock a user account: `sudo passwd -l username`. To unlock: `sudo passwd -u username`. This places `!` or removes `!` from the shadow file.

---



---

[← Previous](08-section-5-etcpasswd-the-user.md) | [↑ Index](index.md) | [Next →](10-section-7-etcgroup-group-database.md)
