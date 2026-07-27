## Key Configuration Parameters

```ini
# shared_buffers — 25% of RAM (not higher!)
shared_buffers = 2GB

# effective_cache_size — OS cache estimate (50-75% of RAM)
effective_cache_size = 6GB

# work_mem — per-sort, per-join, per-hash memory
work_mem = 8MB

# maintenance_work_mem — for VACUUM, CREATE INDEX, ADD FOREIGN KEY
maintenance_work_mem = 256MB

# random_page_cost — how expensive random I/O is (SSD = 1.1, HDD = 4.0)
random_page_cost = 1.1

# max_parallel_workers_per_gather — parallel query workers
max_parallel_workers_per_gather = 4
```



---

[← Previous](49-pgstatstatements-query-statistics.md) | [↑ Index](index.md) | [Next →](51-autovacuum.md)
