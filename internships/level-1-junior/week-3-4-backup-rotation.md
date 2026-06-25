# Internship — Level 1, Week 3-4
## Backup Rotation System

### Real-World Scenario

The company file server has critical data in `/home`, `/etc`, and `/var/log`. There is no backup system. When a user accidentally deletes a project folder, IT needs to restore it — but there's nothing to restore from. Your job: build a reliable, rotating backup system.

### Requirements

Write a script `/usr/local/bin/backup-rotate.sh` that:

1. **Backs up these directories:**
   - `/home/` — user data
   - `/etc/` — system configuration
   - `/var/log/` — logs
   - Each directory gets its own archive

2. **Archive naming:**
   ```
   /backups/daily/home-2026-06-24.tar.gz
   /backups/daily/etc-2026-06-24.tar.gz
   /backups/daily/log-2026-06-24.tar.gz
   ```

3. **Rotation policy:**
   - **Daily:** Keep 7 days (remove older)
   - **Weekly:** Keep 4 weeks (promote Sunday's daily to weekly)
   - **Monthly:** Keep 3 months (promote 1st of month to monthly)

4. **Integrity:**
   - Generate `md5sum` for each archive, store in a manifest file
   - Verify checksums before deleting old backups
   - If checksum fails, alert and DO NOT delete the rotated backup

5. **Reporting:**
   - Email a summary to `it-team@company.com`
   - Format:
     ```
     Backup Report — 2026-06-24
     SUCCESS: /home (2.3 GB, 45s)
     SUCCESS: /etc (340 MB, 12s)
     SUCCESS: /var/log (1.1 GB, 28s)
     Rotation: cleaned 3 daily, 1 weekly, 0 monthly
     Total backup size: 3.7 GB
     ```
   - Use `mail` or `sendmail` (install `mailutils`)

6. **Error handling:**
   - Check that backup destination has enough space (abort if < 10% free)
   - Retry failed backup once after 60 seconds
   - Log everything to `/var/log/backup-rotate.log`

### Cron Configuration

```cron
# Run daily at 2:00 AM
0 2 * * * root /usr/local/bin/backup-rotate.sh
```

### Validation

```bash
# Test: Create some test data
mkdir -p /tmp/test-backup/home/user1 /tmp/test-backup/etc
echo "important data" > /tmp/test-backup/home/user1/file.txt
# Temporarily modify script to use /tmp/test-backup as source
# Run the script and verify archives exist
ls -la /backups/daily/
# Run again and verify rotation works
```

### Deliverables

- `~/internship/backup-rotate.sh`
- `~/internship/backup-rotate.log` — from test run
- `~/internship/backup-policy.md` — one-page document explaining the rotation strategy

### Hints

- `tar czf "$DEST/home-$DATE.tar.gz" -C / home`
- `find /backups/daily/ -name "home-*" -mtime +7 -delete`
- `date +%u` returns 1=Monday...7=Sunday for weekly detection
- `df /backups | awk 'NR==2 {print $5}' | sed 's/%//'` for disk check
- `mail -s "Backup Report" recipient@company.com < report.txt`
