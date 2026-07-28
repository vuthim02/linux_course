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

### Creating a Database from the Command Line

```bash
# Create without connecting first
createdb -U postgres company

# Drop from command line
dropdb -U postgres company
```

### Database Templates

```sql
-- PostgreSQL has two templates: template0 (frozen) and template1 (customizable)
CREATE DATABASE company TEMPLATE template1 ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8';
```

### Key Takeaway
You cannot `DROP DATABASE` while connected to it. Either connect to a different database first (`\c postgres`) or use `dropdb` from the shell.


[← Previous](33-meta-commands-backslash-commands.md) | [↑ Index](index.md) | [Next →](35-table-operations.md)
