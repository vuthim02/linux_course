## EXPLAIN ANALYZE

PostgreSQL's `EXPLAIN ANALYZE` actually **executes** the query:

```sql
EXPLAIN ANALYZE
SELECT e.name, d.name
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE e.salary > 50000;
```

Output walkthrough:

```
Hash Join  (cost=12.34..45.67 rows=100 width=64)
  (actual time=0.123..0.456 rows=95 loops=1)
  Hash Cond: (e.department_id = d.id)
  ->  Seq Scan on employees e  (cost=0.00..25.00 rows=500 width=36)
        (actual time=0.010..0.100 rows=500 loops=1)
        Filter: (salary > 50000)
        Rows Removed by Filter: 405
  ->  Hash  (cost=10.00..10.00 rows=10 width=32)
        (actual time=0.020..0.020 rows=10 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        ->  Seq Scan on departments d  (cost=0.00..10.00 rows=10 width=32)
              (actual time=0.005..0.010 rows=10 loops=1)
Planning Time: 0.050 ms
Execution Time: 0.500 ms
```

**Red flags**:
- `Seq Scan` on large tables (missing index)
- `actual time` much higher than `cost` (bad estimates)
- `Rows Removed by Filter` is very high
- `Sort` without index
- `Execution Time` is too high for the query



---

[← Previous](47-pgbackrest-modern-backup-tool.md) | [↑ Index](index.md) | [Next →](49-pgstatstatements-query-statistics.md)
