## InnoDB Buffer Pool

The **buffer pool** is InnoDB's cache for data and indexes. **This is the #1 performance tuning knob.**

```ini
[mysqld]
# Set to 70-80% of RAM on a dedicated DB server
innodb_buffer_pool_size = 4G

# If > 1GB, use multiple instances (reduces contention)
innodb_buffer_pool_instances = 4
```

Monitor buffer pool:

```sql
-- Hit rate (should be > 99%)
SHOW STATUS LIKE 'Innodb_buffer_pool_read%';

-- Calculate hit rate:
-- (Innodb_buffer_pool_read_requests - Innodb_buffer_pool_reads)
-- / Innodb_buffer_pool_read_requests * 100

-- Current size
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
```




[← Previous](23-slow-query-log.md) | [↑ Index](index.md) | [Next →](25-query-cache-deprecated.md)
