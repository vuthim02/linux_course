## Disk Full (WAL Growth)

### Problem

PostgreSQL can accumulate WAL files in `pg_wal/` if WAL archiving fails or replication lags.

```bash
# Check WAL directory size
sudo du -sh /var/lib/postgresql/16/main/pg_wal/

# Check if WAL archiving is stuck
sudo -u postgres psql -c "SELECT * FROM pg_stat_archiver;"
```

### Fix

```bash
# 1. Identify the problem (disk full, archive command failing)
# 2. Free up space
sudo journalctl --vacuum-time=1d

# 3. Remove old WAL files if archiving failed (CAUTION!)
# Only after ensuring they've been archived or aren't needed
# Check which WAL files can be removed
sudo -u postgres psql -c "SELECT pg_switch_wal();"
# Remove WAL up to the last checkpoint:
sudo -u postgres psql -c "SELECT pg_current_wal_lsn(), pg_last_checkpoint_lsn();"

# 4. Fix the archive command and restart
```

### MariaDB — Binary Log Growth

```bash
# Check binary log disk usage
sudo du -sh /var/log/mysql/

# Remove old binary logs
mysql -u root -p -e "PURGE BINARY LOGS BEFORE NOW() - INTERVAL 3 DAY;"
```




[← Previous](59-maxconnections-reached.md) | [↑ Index](index.md) | [Next →](61-stale-replication.md)
