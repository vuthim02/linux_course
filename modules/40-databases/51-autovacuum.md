## Autovacuum

PostgreSQL uses **MVCC** (Multi-Version Concurrency Control). Dead rows accumulate and must be cleaned up by **VACUUM**. **Autovacuum** runs automatically.

```ini
# Autovacuum settings
autovacuum = on
autovacuum_naptime = 1min
autovacuum_vacuum_threshold = 50
autovacuum_vacuum_scale_factor = 0.2     # 20% of table dead tuples
autovacuum_analyze_threshold = 50
autovacuum_analyze_scale_factor = 0.1    # 10% changed
```

Monitor autovacuum:

```sql
-- Check when tables were last vacuumed
SELECT relname,
       last_vacuum,
       last_autovacuum,
       last_analyze,
       n_dead_tup
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Check autovacuum workers running
SELECT * FROM pg_stat_progress_vacuum;
```



---

[← Previous](50-key-configuration-parameters.md) | [↑ Index](index.md) | [Next →](52-index-types-in-postgresql.md)
