## 🚀 What's Coming in Part 32

**Part 32: Backup Strategies**

You will learn:
- The 3-2-1 backup rule and how to implement it
- Full, incremental, and differential backup strategies
- Backup tools: rsync, tar, dd, duplicity, BorgBackup, restic
- Database backup (MySQL/MariaDB, PostgreSQL) — logical and physical
- Backup to local storage, remote server, cloud (S3, Backblaze B2)
- Backup automation with cron, systemd timers
- Verification and restore testing
- Disaster recovery planning and documentation
- 15 hands-on practices covering all major backup tools

### How Part 31 Connects
LVM snapshots make database backups nearly zero-downtime: snapshot the LV, mount it read-only, dump the data, then remove the snapshot. Understanding LVM is a prerequisite for the advanced backup techniques in Part 32.


[← Previous](22-summary-complete-command-reference-for.md) | [↑ Index](index.md) | [Next →](24-self-test-can-you-answer-these.md)
