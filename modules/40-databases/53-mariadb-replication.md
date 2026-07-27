## MariaDB Replication

### Binary Log and GTID

MariaDB's binary log records all write operations. Replication works by the replica reading the binary log from the primary.

**GTID** (Global Transaction ID) makes replication robust — each transaction has a unique ID.

### Enable Binary Logging (Primary)

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf (primary)
[mysqld]
server_id = 1
log_bin = /var/log/mysql/mariadb-bin
log_bin_index = /var/log/mysql/mariadb-bin.index
binlog_format = ROW
expire_logs_days = 7
gtid_strict_mode = 1
```

### Set Up a Replica

```bash
# 1. On the primary, create a replication user
mysql -u root -p -e "
CREATE USER 'repl'@'192.168.1.%' IDENTIFIED BY 'repl_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.1.%';
FLUSH PRIVILEGES;
"

# 2. Dump the primary
mysqldump -u root -p --all-databases --master-data=2 > /tmp/primary_dump.sql

# 3. Copy the dump to the replica
scp /tmp/primary_dump.sql replica:/tmp/

# 4. Configure replica's my.cnf
# /etc/mysql/mariadb.conf.d/50-server.cnf (replica)
[mysqld]
server_id = 2
log_bin = /var/log/mysql/mariadb-bin
relay_log = /var/log/mysql/mariadb-relay-bin
read_only = 1

# 5. Restart replica
sudo systemctl restart mariadb

# 6. Load the dump on the replica
mysql -u root -p < /tmp/primary_dump.sql

# 7. Start replication
mysql -u root -p -e "
CHANGE MASTER TO
  MASTER_HOST='192.168.1.10',
  MASTER_USER='repl',
  MASTER_PASSWORD='repl_password',
  MASTER_PORT=3306,
  MASTER_USE_GTID=current_pos;
START SLAVE;
"

# 8. Check replication status
mysql -u root -p -e "SHOW SLAVE STATUS\G"
```

### Monitor Replication

```sql
-- On the replica
SHOW SLAVE STATUS\G

-- Key fields to check:
-- Slave_IO_Running: Yes
-- Slave_SQL_Running: Yes
-- Seconds_Behind_Master: 0 (or low)
-- Last_IO_Error: (empty)
-- Last_SQL_Error: (empty)
```

### Troubleshooting Replication

```sql
-- Stop and restart
STOP SLAVE;
START SLAVE;

-- Skip one error (dangerous — only for known safe errors)
STOP SLAVE;
SET GLOBAL sql_slave_skip_counter = 1;
START SLAVE;

-- Re-sync from GTID position
STOP SLAVE;
RESET SLAVE;
CHANGE MASTER TO MASTER_USE_GTID=current_pos;
START SLAVE;
```



---

[← Previous](52-index-types-in-postgresql.md) | [↑ Index](index.md) | [Next →](54-postgresql-streaming-replication.md)
