## 🎯 What You Will Achieve in Part 32

| Level | Focus | Skills |
|-------|-------|--------|
| **Level 1 — Basic** | Backup Philosophy & Classic Tools | 3-2-1 rule, RPO/RTO, `tar` create/extract, `rsync` local/remote, `dd` cloning |
| **Level 2 — Intermediary** | Incremental Backups & Databases | `tar --listed-incremental`, `rsync --link-dest`, `ddrescue`, `dump/restore`, `mysqldump`, `pg_dump`, cron automation |
| **Level 3 — Advanced** | Deduplication, Cloud & DR | Borg, Restic, cloud storage (S3/B2/rclone), restore testing, disaster recovery planning, `fsync`/sparse/COW deep topics |

### Why This Part Matters
Data loss is the one disaster you can never fully recover from — unless you have backups. This part covers everything from basic `tar` archives to cloud-backed deduplicated repositories with ransomware protection. The skills here are what separate a good sysadmin from one who gets fired.

> **Real-world perspective**: Every sysadmin has a story about the backup that was not there when they needed it. Whether it is a database corruption, a ransomware attack, or a simple `rm -rf` typo, backups are the last line of defense. The difference between "inconvenience" and "career-ending" is whether your backups work and whether you have tested restoring them.

**Skills progression in this part**:
- **Basic**: Apply the 3-2-1 rule, create archives with `tar`, sync data with `rsync`, clone disks with `dd`
- **Intermediary**: Implement incremental backups with `tar --listed-incremental` and `rsync --link-dest`, recover failing drives with `ddrescue`, back up databases, automate with cron
- **Advanced**: Deploy Borg and Restic for deduplicated encrypted backups, configure cloud backends (S3, B2), plan disaster recovery with tested runbooks


[↑ Index](index.md) | [Next →](02-level-1-basic-backup-philosophy.md)
