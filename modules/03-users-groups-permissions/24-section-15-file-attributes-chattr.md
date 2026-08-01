## 🔍 Section 15: File Attributes — chattr and lsattr

Beyond standard permissions, Linux supports file attributes that provide additional control.

### Essential Attributes

```bash
lsattr /etc/hosts              # View attributes
chattr +i /etc/shadow          # Make immutable (cannot modify, delete, rename)
chattr -i /etc/shadow          # Remove immutable
chattr +a /var/log/auth.log    # Append-only (can only add data)
chattr +A file.txt             # Don't update atime (access time)
```

| Attribute | Flag | Effect |
|-----------|------|--------|
| Immutable | `+i` | File cannot be modified, deleted, renamed, or linked |
| Append-only | `+a` | Only appending is allowed (ideal for logs) |
| No-atime | `+A` | Do not update access timestamps |
| Undelete | `+u` | Content is saved when deleted (ext4) |
| Secure-deletion | `+s` | Zero-out blocks on delete |
| Synchronous | `+S` | Writes are synchronous (like `sync`) |

### Practical Use Cases

```bash
# Protect critical config from accidental changes
sudo chattr +i /etc/ssh/sshd_config
# Now: rm /etc/ssh/sshd_config → "Operation not permitted"
# To modify: remove attr → edit → restore attr

# Audit logs that should only grow
sudo chattr +a /var/log/audit/audit.log

# Restrict cron/at for security
sudo chattr +i /etc/crontab
sudo chattr +i /var/spool/cron
```



[← Previous](23-self-test-can-you-answer-these.md) | [↑ Index](index.md) | [Next →](25-section-16-linux-capabilities.md)
