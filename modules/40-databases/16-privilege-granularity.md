## Privilege Granularity

Privileges can be granted at these levels:

| Level | Syntax | Scope |
|-------|--------|-------|
| **Global** | `ON *.*` | All databases, all tables |
| **Database** | `ON db.*` | All tables in a database |
| **Table** | `ON db.table` | Specific table |
| **Column** | `ON db.table (col1, col2)` | Specific columns |
| **Procedure** | `ON PROCEDURE db.proc` | Stored procedure |

Common privilege types:

```sql
-- Read-only
GRANT SELECT ON db.* TO 'reader'@'%';

-- Read-write
GRANT SELECT, INSERT, UPDATE, DELETE ON db.* TO 'writer'@'%';

-- DDL operations
GRANT CREATE, ALTER, DROP, INDEX ON db.* TO 'developer'@'%';

-- Admin (but not GRANT)
GRANT ALL PRIVILEGES ON db.* TO 'owner'@'%';

-- Superuser
GRANT ALL PRIVILEGES ON *.* TO 'superadmin'@'localhost' WITH GRANT OPTION;
```



---

[← Previous](15-userhost-format.md) | [↑ Index](index.md) | [Next →](17-view-effective-privileges.md)
