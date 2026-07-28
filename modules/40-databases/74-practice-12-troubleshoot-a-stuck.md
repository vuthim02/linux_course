## Practice 12: Troubleshoot a Stuck Query

```bash
# 1. Start a long transaction
mysql -u invapp -pinventory_pass -e "BEGIN; UPDATE inventory.items SET quantity = quantity - 1 WHERE id = 1; SELECT SLEEP(60); COMMIT;" &

# 2. In another terminal, find and kill it
sudo mysql -e "SHOW PROCESSLIST;"
sudo mysql -e "KILL <thread_id>;"

# Same for PostgreSQL
psql -h localhost -U invadmin -d inventory -c "BEGIN; UPDATE items SET quantity = quantity - 1 WHERE id = 1; SELECT pg_sleep(60); COMMIT;" &
sudo -u postgres psql -c "SELECT pid, query FROM pg_stat_activity WHERE state = 'active';"
sudo -u postgres psql -c "SELECT pg_cancel_backend(<pid>);"
```

### MariaDB: Identifying Stuck Queries

```sql
-- Find long-running transactions
SHOW PROCESSLIST;

-- Look for "Locked" status
SELECT id, user, host, db, command, time, state, info
FROM information_schema.processlist
WHERE command != 'Sleep' AND time > 5;

-- Kill a specific thread
KILL <id>;
```

### PostgreSQL: Identifying Stuck Queries

```sql
-- Find active queries running longer than 30 seconds
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '30 seconds'
AND state = 'active';

-- Cancel (graceful) vs Terminate (forceful)
SELECT pg_cancel_backend(<pid>);   -- sends SIGINT to backend
SELECT pg_terminate_backend(<pid>); -- sends SIGTERM
```

### Key Takeaway
`pg_cancel_backend` is safe — it cancels the current query without disconnecting. Use `pg_terminate_backend` only when the process is truly stuck.


[← Previous](73-practice-11-pt-query-digest-percona-toolkit.md) | [↑ Index](index.md) | [Next →](75-practice-13-database-size-monitoring.md)
