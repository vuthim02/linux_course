## Query Cache (Deprecated)

MariaDB had a query cache, but it's **deprecated** and removed in MySQL 8.0+:

```ini
# MariaDB 10.1+ — not recommended
query_cache_type = 0
query_cache_size = 0
```

### Why Was It Deprecated?

The query cache locks the **entire cache** on any write operation (INSERT, UPDATE, DELETE). In write-heavy workloads, this becomes a severe bottleneck — servers with high write throughput actually performed *worse* with the query cache enabled.

### What Replaced It?

- **InnoDB Buffer Pool** — caches data and index pages in memory (the primary performance lever)
- **ProxySQL / application-level caching** — Redis, Memcached for hot data
- **MariaDB 10.1.7+**: `query_cache_type = DEMAND` (only caches queries marked with `SQL_CACHE`)

### Quick Recommendation

```ini
# Always disable in modern MySQL/MariaDB
query_cache_type = 0
query_cache_size = 0
```

Focus tuning effort on `innodb_buffer_pool_size` instead — it provides far better performance scaling.


[← Previous](24-innodb-buffer-pool.md) | [↑ Index](index.md) | [Next →](26-schema-optimization-tips.md)
