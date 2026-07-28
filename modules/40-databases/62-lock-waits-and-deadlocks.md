## Lock Waits and Deadlocks

### MariaDB

```sql
-- Show current locks
SHOW OPEN TABLES WHERE In_use > 0;
SHOW ENGINE INNODB STATUS\G

-- Find blocking transactions
SELECT * FROM information_schema.INNODB_LOCK_WAITS;
SELECT * FROM information_schema.INNODB_TRX\G

-- Kill blocking transaction
KILL <trx_mysql_thread_id>;
```

### PostgreSQL

```sql
-- Find blocked queries
SELECT blocked.pid AS blocked_pid,
       blocked.query AS blocked_query,
       blocking.pid AS blocking_pid,
       blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocked.pid != blocking.pid
WHERE blocked.wait_event_type = 'Lock';

-- Cancel blocking query
SELECT pg_cancel_backend(<blocking_pid>);

-- Or terminate
SELECT pg_terminate_backend(<blocking_pid>);

-- Deadlock log (check PostgreSQL logs)
sudo tail -f /var/log/postgresql/postgresql-16-main.log
-- Search for "deadlock detected"
```


# 15. Hands-On Practices




[← Previous](61-stale-replication.md) | [↑ Index](index.md) | [Next →](63-practice-1-secure-mariadb-installation.md)
