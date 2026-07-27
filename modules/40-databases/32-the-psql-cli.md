## The psql CLI

```bash
# Connect as postgres (peer auth — must be root or postgres OS user)
sudo -u postgres psql

# Connect to specific database
sudo -u postgres psql mydb

# Connect via TCP (password auth)
psql -h localhost -U myuser -d mydb -p 5432

# Execute a single command
psql -U postgres -c "SELECT version();"

# Execute a SQL file
psql -U postgres -f /tmp/backup.sql

# Connection info
\conninfo
```



---

[← Previous](31-authentication-methods.md) | [↑ Index](index.md) | [Next →](33-meta-commands-backslash-commands.md)
