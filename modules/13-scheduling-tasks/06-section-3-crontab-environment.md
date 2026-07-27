## 🔍 Section 3: crontab Environment

cron runs commands in a minimal environment. This is a COMMON source of bugs.

### The Problem

```bash
# When you type this in terminal, it works:
mysqldump -u root mydb > /tmp/backup.sql

# When cron runs it, it FAILS because:
# 1. PATH is different (might not include /usr/bin)
# 2. HOME is different
# 3. No terminal (TTY) available
# 4. Environment variables are not set
```

### The Solution — Set Environment in Crontab

```bash
# Set variables at the TOP of your crontab
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOME=/home/username
MAILTO=admin@example.com

# Now commands will work
0 2 * * * mysqldump -u root mydb > /tmp/backup.sql
```

### Cron Environment Variables

| Variable | Purpose |
|----------|---------|
| SHELL | Shell to use for commands (default: /bin/sh) |
| PATH | Where to find executables (default: /usr/bin:/bin) |
| HOME | Home directory (default: user's home) |
| MAILTO | Who gets cron output via email (default: user) |
| LOGNAME | Username |

### Always Use Full Paths

```bash
# Bad cron job (cron might not find 'tar'):
0 3 * * * tar -czf /backup/www.tar.gz /var/www

# Good cron job:
0 3 * * * /usr/bin/tar -czf /backup/www.tar.gz /var/www

# Even better — put PATH in crontab:
PATH=/usr/bin:/bin:/usr/local/bin
0 3 * * * tar -czf /backup/www.tar.gz /var/www
```

---



---

[← Previous](05-level-2-intermediary-scheduling-workflows.md) | [↑ Index](index.md) | [Next →](07-section-4-cron-output-and.md)
