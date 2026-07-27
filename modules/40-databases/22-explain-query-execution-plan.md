## EXPLAIN — Query Execution Plan

```sql
EXPLAIN SELECT e.name, d.name
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE e.salary > 50000;
```

Output columns:

| Column | Meaning |
|--------|---------|
| `id` | SELECT identifier |
| `select_type` | SIMPLE, PRIMARY, SUBQUERY, etc. |
| `table` | Table name |
| `type` | Access method (ALL = full table scan, ref, eq_ref, const) |
| `possible_keys` | Indexes that could be used |
| `key` | Index actually used |
| `rows` | Estimated rows examined |
| `Extra` | Using index, Using where, Using filesort, etc. |

**Red flags**:
- `type: ALL` (full table scan) on large tables
- `rows` is very high
- `Extra: Using filesort` (sort without index)
- `Extra: Using temporary` (temp table for GROUP BY)



---

[← Previous](21-mariadb-dump-modern-wrapper.md) | [↑ Index](index.md) | [Next →](23-slow-query-log.md)
