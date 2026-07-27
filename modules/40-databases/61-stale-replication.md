## Stale Replication

### MariaDB

```sql
SHOW SLAVE STATUS\G
-- Check: Slave_IO_Running, Slave_SQL_Running, Last_IO_Error, Last_SQL_Error

-- If IO thread is not running:
-- Network issue? Can the replica reach the primary?
-- Check with: ping, telnet, mysql -h primary -u repl -p

-- If SQL thread stopped (duplicate key, missing row):
STOP SLAVE;
SET GLOBAL sql_slave_skip_counter = 1;
START SLAVE;

-- Or re-sync:
STOP SLAVE;
RESET SLAVE;
CHANGE MASTER TO MASTER_USE_GTID=current_pos;
START SLAVE;
```

### PostgreSQL

```sql
-- Check replication status on primary
SELECT client_addr, state, write_lag, flush_lag, replay_lag
FROM pg_stat_replication
WHERE application_name = 'replica1';

-- On replica, check lag
SELECT pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()) AS lag_bytes;

-- If lag is growing:
-- Is the replica powerful enough? CPU, I/O?
-- Is network bandwidth saturated?
-- Try increasing:
--   max_wal_senders, max_worker_processes, wal_receiver_buffer_size
```



---

[← Previous](60-disk-full-wal-growth.md) | [↑ Index](index.md) | [Next →](62-lock-waits-and-deadlocks.md)
