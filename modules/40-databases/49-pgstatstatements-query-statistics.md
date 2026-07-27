## pg_stat_statements — Query Statistics

```sql
-- Enable in postgresql.conf:
-- shared_preload_libraries = 'pg_stat_statements'
-- Then restart and CREATE EXTENSION

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top queries by total time
SELECT queryid,
       ROUND(total_exec_time::numeric, 2) AS total_ms,
       calls,
       ROUND(mean_exec_time::numeric, 2) AS avg_ms,
       ROUND(rows / calls::numeric, 0) AS avg_rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Top queries by average time
SELECT queryid,
       ROUND(mean_exec_time::numeric, 2) AS avg_ms,
       calls,
       ROUND(total_exec_time::numeric, 2) AS total_ms,
       SUBSTRING(query, 1, 60) AS query_preview
FROM pg_stat_statements
WHERE calls > 10
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Reset statistics
SELECT pg_stat_statements_reset();
```



---

[← Previous](48-explain-analyze.md) | [↑ Index](index.md) | [Next →](50-key-configuration-parameters.md)
