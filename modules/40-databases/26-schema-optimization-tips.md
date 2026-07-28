## Schema Optimization Tips

1. **Choose the right data types**:
   - `INT` vs `BIGINT` — use what you actually need
   - `VARCHAR(255)` wastes space — use realistic limits
   - `DATETIME` (5 bytes) vs `TIMESTAMP` (4 bytes)
   - `DECIMAL` for exact currency — never `FLOAT`

2. **Primary key matters**:
   - Use `INT AUTO_INCREMENT` or `UUID` (but UUIDs fragment B-trees)
   - InnoDB stores rows in primary key order (clustered index)

3. **Index selectively**:
   - Index columns used in `WHERE`, `JOIN`, `ORDER BY`
   - Don't over-index (slow down writes)
   - Composite indexes: order matters (most selective first)

```sql
-- Good index for: WHERE department_id = ? AND salary > ?
CREATE INDEX idx_dept_salary ON employees(department_id, salary);

-- This index can also serve: WHERE department_id = ?
-- But NOT: WHERE salary = ?
```

4. **Use `EXPLAIN` before deploying queries to production**




[← Previous](25-query-cache-deprecated.md) | [↑ Index](index.md) | [Next →](27-indexing-types-in-mariadbmysql.md)
