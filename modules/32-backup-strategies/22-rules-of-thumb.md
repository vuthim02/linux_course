## 📏 Rules of Thumb

### The Backup Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Follow 3-2-1** | 3 copies, 2 media, 1 offsite | Data safety |
| **Test restores** | Verify backups work | Recovery |
| **Automate backups** | Cron or systemd timer | Reliability |
| **Encrypt offsite** | Protect sensitive data | Security |
| **Document procedures** | Know how to restore | Readiness |

### The "Backup Failed" Checklist

```bash
# 1. Check logs:
tail -f /var/log/backup.log

# 2. Check disk space:
df -h

# 3. Check permissions:
ls -la /backup/directory

# 4. Test manually:
/usr/local/bin/backup.sh

# 5. Check cron:
crontab -l
```

---

**Why these rules matters:** Following these rules ensures your backups are reliable and restorable.

[← Previous](29-self-test.md) | [↑ Index](index.md)
