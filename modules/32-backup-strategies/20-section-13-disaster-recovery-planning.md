## 🔍 Section 13: Disaster Recovery Planning

### DR Checklist

```
System Configuration:
☐ /etc/              (system config)
☐ /usr/local/etc/    (local software config)
☐ SSH host keys      (/etc/ssh/ssh_host_*)
☐ SSL certificates   (/etc/ssl/, /etc/letsencrypt/)
☐ Package list       (dpkg --get-selections / rpm -qa)

Databases:
☐ MySQL/MariaDB      (mysqldump --all-databases)
☐ PostgreSQL         (pg_dumpall)
☐ SQLite             (.backup)
☐ MongoDB            (mongodump)

Application Data:
☐ /var/www/          (web content)
☐ /home/             (user data)
☐ Container volumes  (Docker/Podman)
```

### Backup Policy Template

```markdown


---

[← Previous](19-section-12-restore-testing.md) | [↑ Index](index.md) | [Next →](21-schedule.md)
