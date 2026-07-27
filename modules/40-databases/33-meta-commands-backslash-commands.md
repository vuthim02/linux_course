## Meta-Commands (Backslash Commands)

```sql
-- List all databases
\l
\l+                         -- with sizes and descriptions

-- Connect to a database
\c mydb

-- List tables in current database
\dt
\dt+                        -- with additional info

-- List all schemas
\dn

-- Describe a table
\d employees
\d+ employees               -- with storage details

-- List views, sequences, indexes
\dv
\ds
\di

-- List all roles (users)
\du
\du+                        -- with member of

-- List functions
\df

-- Show query history
\s

-- Show current database and user
\conninfo

-- Execute shell command
\! ls -la

-- Show execution time of queries
\timing on

-- Help
\h CREATE TABLE
\?

-- Quit
\q
```



---

[← Previous](32-the-psql-cli.md) | [↑ Index](index.md) | [Next →](34-database-operations.md)
