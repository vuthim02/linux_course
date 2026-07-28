## Best Practices

1. **No password in command line** — use `.my.cnf` for scripts:

```ini
# ~/.my.cnf
[client]
user = backupuser
password = SuperSecretPass
host = localhost
```

```bash
chmod 600 ~/.my.cnf
```

2. **Least privilege** — grant only what's needed
3. **No remote root** — `root` should only connect via socket
4. **Separate users per application** — easier to audit and revoke


# 5. MariaDB Backup




[← Previous](17-view-effective-privileges.md) | [↑ Index](index.md) | [Next →](19-mysqldump-mariadb-dump.md)
