## 🔍 Section 7: /etc/group — Group Database

```bash
cat /etc/group
```

```
developers:x:1001:alice,bob,charlie
│          │ │    │
│          │ │    └── Supplementary members (comma-separated)
│          │ └─────── Group ID (GID)
│          └───────── Group password (x = managed by shadow)
└──────────────────── Group name
```

### The Primary vs Supplementary Groups

Every user has exactly **one primary group** (from `/etc/passwd` field 4) and can belong to **many supplementary groups** (from `/etc/group`).

```bash
# When alice creates a file, the group is her PRIMARY group:
$ touch test.txt
$ ls -l test.txt
-rw-rw-r-- 1 alice alice 0 Jan 15 10:30 test.txt
#                    └── primary group (also called "alice")
```

> 🔍 **Reverse Engineering Insight:** By default every user gets a "User Private Group" (UPG) — a group with the same name as the user. This is why `alice` owns both user and group. This prevents the need for a shared "users" group that could accidentally give access.





[← Previous](09-section-6-etcshadow-the-password.md) | [↑ Index](index.md) | [Next →](11-section-8-user-management-commands.md)
