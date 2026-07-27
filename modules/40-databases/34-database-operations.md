## Database Operations

```sql
-- Create database
CREATE DATABASE company;
CREATE DATABASE company OWNER 'appuser' ENCODING 'UTF8';

-- List databases (from psql)
\l

-- Connect to database
\c company

-- Drop database (cannot drop while connected to it)
DROP DATABASE company;
```



---

[← Previous](33-meta-commands-backslash-commands.md) | [↑ Index](index.md) | [Next →](35-table-operations.md)
