## 🔍 Section 6: Log Rotation with logrotate

Log files grow endlessly. logrotate manages this automatically.

### How logrotate Works

```
1. Runs daily from cron (/etc/cron.daily/logrotate)
2. Reads config from /etc/logrotate.conf and /etc/logrotate.d/*
3. Checks if any log file needs rotation (based on size, age)
4. Renames current log (nginx.log → nginx.log.1)
5. Creates new empty log file
6. Optionally compresses old logs (nginx.log.2.gz)
7. Removes logs older than retention period
8. Sends signal to application to reopen logs
```

### Main Configuration

```bash
cat /etc/logrotate.conf
```

```
# Global settings
weekly                    # Rotate weekly
rotate 4                  # Keep 4 weeks of backups
create                    # Create new file after rotation
dateext                   # Use date as suffix
compress                  # Compress old logs (gzip)

# Include additional config
include /etc/logrotate.d
```

### Per-Service Configuration

```bash
cat /etc/logrotate.d/nginx
```

```
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 $(cat /var/run/nginx.pid)
    endscript
}
```

### Common logrotate Directives

| Directive | Purpose |
|-----------|---------|
| `daily` | Rotate every day |
| `weekly` | Rotate every week |
| `monthly` | Rotate every month |
| `rotate N` | Keep N old logs |
| `size SIZE` | Rotate when file exceeds size (e.g., `size 100M`) |
| `compress` | Compress with gzip |
| `delaycompress` | Skip compression on most recent rotated file |
| `missingok` | Don't error if log file is missing |
| `notifempty` | Don't rotate empty files |
| `create MODE USER GROUP` | Create new file with these permissions |
| `postrotate/endscript` | Run commands after rotation |
| `prerotate/endscript` | Run commands before rotation |
| `sharedscripts` | Run postrotate once for all matching files |
| `dateext` | Use date instead of number suffix |

### Testing logrotate

```bash
# Dry run (shows what WOULD happen)
sudo logrotate -d /etc/logrotate.conf

# Force rotation
sudo logrotate -f /etc/logrotate.conf

# Force rotation of specific config
sudo logrotate -f /etc/logrotate.d/nginx

# Show logrotate status
cat /var/lib/logrotate/status
```

### Custom logrotate Example

```bash
# Create a config for your custom app
sudo tee /etc/logrotate.d/myapp << 'EOF'
/var/log/myapp/*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 640 myapp myapp
    sharedscripts
    postrotate
        systemctl reload myapp 2>/dev/null || true
    endscript
}
EOF
```

---



---

[← Previous](08-section-5-journald-deep-dive.md) | [↑ Index](index.md) | [Next →](10-level-3-advanced-centralized-logging.md)
