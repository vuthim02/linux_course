## max_connections Reached

### MariaDB

```sql
SHOW VARIABLES LIKE 'max_connections';
SHOW STATUS LIKE 'Threads_connected';

-- Increase temporarily (until restart)
SET GLOBAL max_connections = 500;

-- Permanent change in my.cnf:
-- [mysqld]
-- max_connections = 500
```

### PostgreSQL

```sql
SHOW max_connections;
SELECT count(*) FROM pg_stat_activity;

-- Needs restart (can't change at runtime)
-- ALTER SYSTEM max_connections = '500';
-- sudo systemctl restart postgresql
```




[← Previous](58-connection-refused.md) | [↑ Index](index.md) | [Next →](60-disk-full-wal-growth.md)
