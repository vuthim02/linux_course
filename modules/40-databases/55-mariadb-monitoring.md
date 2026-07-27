## MariaDB Monitoring

### SHOW PROCESSLIST

```sql
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;

-- Kill a stuck query
KILL 1234;
KILL CONNECTION 1234;
KILL QUERY 1234;    -- just the query, keep connection
```

### Monitor Connections

```sql
-- Current connections
SHOW STATUS LIKE 'Threads_connected';
SHOW VARIABLES LIKE 'max_connections';

-- Connection usage percentage
SELECT (SELECT VARIABLE_VALUE FROM information_schema.GLOBAL_STATUS
        WHERE VARIABLE_NAME = 'Threads_connected') /
       (SELECT VARIABLE_VALUE FROM information_schema.GLOBAL_VARIABLES
        WHERE VARIABLE_NAME = 'max_connections') * 100 AS connection_pct;
```

### Database Size

```sql
-- Size of all databases
SELECT table_schema AS database_name,
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.TABLES
GROUP BY table_schema;

-- Size of a specific table
SELECT table_name,
       ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'company' AND table_name = 'employees';
```

### Slow Query Log Monitoring

```bash
# Watch slow queries in real time
sudo tail -f /var/log/mysql/mariadb-slow.log

# Count slow queries per minute
sudo grep "$(date +%H:%M)" /var/log/mysql/mariadb-slow.log | wc -l

# Analyze with Percona Toolkit
sudo apt install percona-toolkit
pt-query-digest /var/log/mysql/mariadb-slow.log
```



---

[← Previous](54-postgresql-streaming-replication.md) | [↑ Index](index.md) | [Next →](56-postgresql-monitoring.md)
