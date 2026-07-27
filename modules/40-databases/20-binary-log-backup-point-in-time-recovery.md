## Binary Log Backup (Point-in-Time Recovery)

Binary logs record every write operation. After restoring a full backup, replay binary logs to recover to a specific point.

### Enable Binary Logging

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
log_bin = /var/log/mysql/mariadb-bin
expire_logs_days = 7
max_binlog_size = 100M
```

### Tools

```bash
# List binary logs
mysql -u root -p -e "SHOW BINARY LOGS;"

# View binary log contents (as SQL)
mysqlbinlog /var/log/mysql/mariadb-bin.000001

# Replay binary logs (after restoring full backup)
mysqlbinlog /var/log/mysql/mariadb-bin.000001 /var/log/mysql/mariadb-bin.000002 \
    | mysql -u root -p

# Recover to a specific time
mysqlbinlog --stop-datetime="2026-06-23 14:30:00" /var/log/mysql/mariadb-bin.* \
    | mysql -u root -p

# Recover to a specific position
mysqlbinlog --stop-position=123456 /var/log/mysql/mariadb-bin.* \
    | mysql -u root -p
```

### Full Point-in-Time Recovery Procedure

```bash
# 1. Restore the full backup
mysql -u root -p < full_backup.sql

# 2. Replay binary logs since the backup
mysqlbinlog --start-datetime="2026-06-22 03:00:00" \
    --stop-datetime="2026-06-23 09:15:00" \
    /var/log/mysql/mariadb-bin.* \
    | mysql -u root -p

# 3. Verify data
mysql -u root -p -e "SELECT COUNT(*) FROM company.orders;"
```



---

[← Previous](19-mysqldump-mariadb-dump.md) | [↑ Index](index.md) | [Next →](21-mariadb-dump-modern-wrapper.md)
