## Indexing Types in MariaDB/MySQL

| Index Type | Description | Use Case |
|-----------|-------------|----------|
| **B-tree** (default) | Balanced tree — good for equality and range | Most queries |
| **FULLTEXT** | Word-based search | `MATCH ... AGAINST` |
| **HASH** | Only in MEMORY engine | Equality lookups |
| **SPATIAL** | GIS data | Geometry columns |
| **UNIQUE** | Enforces uniqueness | Email, username |

---

# 7. PostgreSQL Installation



---

[← Previous](26-schema-optimization-tips.md) | [↑ Index](index.md) | [Next →](28-install-postgresql.md)
