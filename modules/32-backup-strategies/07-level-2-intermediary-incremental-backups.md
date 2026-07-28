## ⭐ Level 2: Intermediary — Incremental Backups and Databases

![Incremental backup strategy with rsync --link-dest](https://upload.wikimedia.org/wikipedia/commons/6/6a/Incremental_backup.svg)

> **Level 2 Goal:** Implement incremental backups with `tar --listed-incremental` and `rsync --link-dest`, recover failing drives with `ddrescue`, use `dump/restore` for ext4, perform database backups with `mysqldump` and `pg_dump`, and automate the entire workflow with cron.

### What You'll Cover
- Incremental backups with `tar --listed-incremental` (snapshot files)
- `rsync --link-dest` for hardlinked incremental backups
- `ddrescue` for recovering data from failing drives
- `dump/restore` for ext4-level backups
- Database backups: `mysqldump`, `pg_dump`, logical vs physical
- Automating backups with cron jobs and rotation scripts

Incremental backups are the foundation of efficient backup strategies. Instead of copying everything every time, you only copy what changed — saving time, bandwidth, and storage.

At this level you will practice:

- **`tar --listed-incremental`**: `tar czf full.tar.gz --listed-incremental=snapshot.snar /data` for the first backup. Subsequent runs with the same snapshot file create incrementals. The snapshot file tracks which files have changed. Restore with `tar xzf incr_1.tar.gz --listed-incremental=snapshot.snar`.
- **`rsync --link-dest`**: `rsync -av --link-dest=/backup/latest /data/ /backup/$(date +%F)/` creates hardlinks to unchanged files in the previous backup. This gives you full backups at the cost of only the changed data. The `latest` symlink points to the most recent backup.
- **`ddrescue`**: `ddrescue -f -n /dev/sdb /backup/disk.img rescue.log` copies a failing drive, skipping bad sectors first and retrying them later. The log file allows resuming interrupted recoveries. Unlike `dd`, it does not abort on read errors.
- **Database backups**: `mysqldump --all-databases --single-transaction > mysql_backup.sql` gives a consistent snapshot. `pg_dump -Fc dbname > pg_backup.dump` creates a custom-format dump. Always test restoring these to verify integrity.
- **Automation**: Use cron with a rotation script that keeps daily backups for 7 days, weekly for 4 weeks, and monthly for 12 months. The script should also verify checksums and send email alerts on failures.


[← Previous](06-section-4-dd-and-ddrescue.md) | [↑ Index](index.md) | [Next →](08-section-2-tar-advanced.md)
