## WAL Archiving (Continuous Archiving)

PostgreSQL's **Write-Ahead Log** (WAL) enables point-in-time recovery.

### Enable WAL Archiving

```ini
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/16/archive/%f'
archive_timeout = 60    # force a WAL switch at least every 60 seconds
```

### Create the Archive Directory

```bash
sudo mkdir -p /var/lib/postgresql/16/archive
sudo chown postgres:postgres /var/lib/postgresql/16/archive
sudo systemctl restart postgresql
```

### Take a Base Backup

```bash
# As postgres user
sudo -u postgres psql -c "SELECT pg_start_backup('base_backup_20260623');"

# Copy data directory
sudo cp -a /var/lib/postgresql/16/main /var/lib/postgresql/16/base_backup

# Stop the backup
sudo -u postgres psql -c "SELECT pg_stop_backup();"
```

### Point-in-Time Recovery

```bash
# 1. Stop PostgreSQL
sudo systemctl stop postgresql

# 2. Restore base backup
sudo rm -rf /var/lib/postgresql/16/main
sudo cp -a /var/lib/postgresql/16/base_backup /var/lib/postgresql/16/main

# 3. Create recovery signal file
sudo touch /var/lib/postgresql/16/main/recovery.signal

# 4. Create recovery.conf
# /var/lib/postgresql/16/main/postgresql.auto.conf
# restore_command = 'cp /var/lib/postgresql/16/archive/%f %p'
# recovery_target_time = '2026-06-23 14:30:00'

# 5. Start PostgreSQL (it will replay WAL)
sudo systemctl start postgresql

# 6. Check recovery status
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```




[← Previous](45-restore-plain-sql.md) | [↑ Index](index.md) | [Next →](47-pgbackrest-modern-backup-tool.md)
