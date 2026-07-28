## Indexing Types in MariaDB/MySQL

| Index Type | Description | Use Case |
|-----------|-------------|----------|
| **B-tree** (default) | Balanced tree — good for equality and range | Most queries |
| **FULLTEXT** | Word-based search | `MATCH ... AGAINST` |
| **HASH** | Only in MEMORY engine | Equality lookups |
| **SPATIAL** | GIS data | Geometry columns |
| **UNIQUE** | Enforces uniqueness | Email, username |

### Creating Indexes

```sql
-- Simple B-tree index
CREATE INDEX idx_email ON users(email);

-- Unique index (enforces no duplicates)
CREATE UNIQUE INDEX idx_username ON users(username);

-- Composite index (multi-column)
CREATE INDEX idx_name_dept ON employees(last_name, department_id);

-- Full-text index
CREATE FULLTEXT INDEX idx_bio ON users(bio);
SELECT * FROM users WHERE MATCH(bio) AGAINST('linux administrator');
```

### When NOT to Index

- Small tables (< 1000 rows) — full scan is faster
- Columns with low cardinality (e.g., boolean `is_active`)
- Columns that are frequently updated (index maintenance overhead)

### Key Takeaway
The **composite index** order matters: `INDEX(a, b)` can serve queries on `(a)` and `(a, b)` but NOT on `(b)` alone. Design indexes to match your most common query patterns.


# 7. PostgreSQL Installation


[← Previous](26-schema-optimization-tips.md) | [↑ Index](index.md) | [Next →](28-install-postgresql.md)
