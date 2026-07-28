## 🔍 Section 9: Real Sysadmin Scheduling Patterns

### Pattern 1: Log Rotation

```bash
# /etc/cron.daily/logrotate
# Most distros handle this automatically
# But you can add custom rotation rules in /etc/logrotate.d/

# Test logrotate manually:
sudo logrotate -d /etc/logrotate.conf    # Dry run
sudo logrotate -f /etc/logrotate.conf    # Force run
```

### Pattern 2: Database Backup

```bash
# cron: daily backup at 2 AM
0 2 * * * /usr/local/bin/mysql-backup.sh

# mysql-backup.sh:
#!/bin/bash
BACKUP_DIR=/var/backups/mysql
TIMESTAMP=$(date +\%Y-\%m-\%d_\%H:\%M:\%S)
mkdir -p $BACKUP_DIR
mysqldump --all-databases | gzip > $BACKUP_DIR/all-dbs_$TIMESTAMP.sql.gz
find $BACKUP_DIR -type f -mtime +30 -delete  # Keep 30 days
```

### Pattern 3: System Cleanup

```bash
# cron: clean temp files every Sunday at 3 AM
0 3 * * 0 /usr/local/bin/cleanup.sh

# cleanup.sh:
#!/bin/bash
find /tmp -type f -atime +7 -delete
find /var/tmp -type f -atime +7 -delete
apt autoremove -y 2>/dev/null || dnf autoremove -y 2>/dev/null
```

### Pattern 4: Health Check

```bash
# cron: monitor disk space every hour
0 * * * * /usr/local/bin/disk-check.sh

# disk-check.sh:
#!/bin/bash
THRESHOLD=90
df -h | awk -v threshold=$THRESHOLD 'NR>1 {gsub(/%/,"",$5); if($5>threshold) print "WARNING: "$6" is "$5"% full"}' \
    | mail -s "Disk Space Alert on $(hostname)" admin@example.com
```

### Pattern 5: Certificate Renewal

```bash
# Let's Encrypt certs renew automatically via cron/systemd timer
# Certbot usually installs this automatically:
ls /etc/cron.d/certbot
# or
systemctl list-timers | grep certbot
```





[← Previous](12-level-3-advanced-real-world-patterns.md) | [↑ Index](index.md) | [Next →](14-deep-understanding-how-scheduling-really.md)
