## 🔍 Section 9: Database Backup

### MySQL/MariaDB — mysqldump

```bash
# All databases
mysqldump --all-databases --single-transaction --routines --events > backup.sql

# Single database
mysqldump --single-transaction mydatabase > mydatabase.sql

# Compressed
mysqldump --all-databases --single-transaction | gzip > backup-$(date +%F).sql.gz

# Restore
mysql < backup.sql
zcat backup-2025-01-12.sql.gz | mysql
```

`--single-transaction` gives a consistent snapshot without locking tables (InnoDB).

### PostgreSQL — pg_dump / pg_dumpall

```bash
# Single database
pg_dump mydatabase > mydatabase.sql

# All databases
pg_dumpall > all-databases.sql

# Custom format (compressed, selective restore, parallel)
pg_dump -Fc mydatabase > mydatabase.dump
pg_restore -d mydatabase -t mytable mydatabase.dump   # restore single table

# Directory format (parallel dump/restore)
pg_dump -Fd -j 4 mydatabase -f /backups/pg-mydatabase/
pg_restore -d mydatabase -j 4 /backups/pg-mydatabase/

# Restore
psql mydatabase < mydatabase.sql
pg_restore -d mydatabase mydatabase.dump
```

### PostgreSQL — WAL Archiving (Point-in-Time Recovery)

```bash
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backups/pg-wal/%f'

# Base backup
psql -c "SELECT pg_start_backup('base_$(date +%F)');"
tar czf /backups/pg-base-$(date +%F).tar.gz /var/lib/postgresql/16/main/
psql -c "SELECT pg_stop_backup();"

# Restore to specific time:
# 1. Extract base backup
# 2. Set restore_command and recovery_target_time in postgresql.conf
# 3. Start PostgreSQL
```

### SQLite

```bash
sqlite3 /var/lib/mydatabase.db ".backup /backups/mydatabase-$(date +%F).db"
sqlite3 /var/lib/mydatabase.db ".dump" | gzip > /backups/mydatabase.sql.gz
```

---



---

[← Previous](11-section-5-dumprestore.md) | [↑ Index](index.md) | [Next →](13-section-10-automation.md)
