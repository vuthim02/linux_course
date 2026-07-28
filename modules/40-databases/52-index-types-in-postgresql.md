## Index Types in PostgreSQL

| Index Type | Description | Use Case |
|-----------|-------------|----------|
| **B-tree** (default) | Balanced tree — equality and range | Most general purpose |
| **Hash** | Equality only | Simple lookups |
| **GiST** | Generalized Search Tree | Full-text, geometry, ranges |
| **GIN** | Generalized Inverted Index | Arrays, JSONB, full-text |
| **BRIN** | Block Range Index | Huge tables with natural ordering (logs, time-series) |
| **SP-GiST** | Space-partitioned GiST | GIS, network addresses |

```sql
-- B-tree (default)
CREATE INDEX idx_emp_salary ON employees(salary);

-- Hash (equality only)
CREATE INDEX idx_emp_email ON employees USING HASH (email);

-- BRIN — great for append-only tables (logs)
CREATE INDEX idx_log_created ON logs USING BRIN (created_at);

-- GIN — for JSONB queries
CREATE INDEX idx_product_attrs ON products USING GIN (attributes);

-- Partial index — only index relevant rows
CREATE INDEX idx_active_users ON users(email) WHERE active = true;

-- Covering index — includes extra columns (no need to visit table)
CREATE INDEX idx_emp_dept_salary ON employees(department_id, salary);
```


# 12. Replication




[← Previous](51-autovacuum.md) | [↑ Index](index.md) | [Next →](53-mariadb-replication.md)
