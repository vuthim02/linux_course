## pg_dump — Single Database Backup

```bash
# Dump a single database (plain SQL)
pg_dump -U postgres company > company_backup.sql

# Custom format (compressed, flexible)
pg_dump -U postgres -Fc company > company_backup.dump

# Directory format (parallel capable)
pg_dump -U postgres -Fd company -j 4 -f /backup/company_dir/

# Exclude data (schema only)
pg_dump -U postgres --schema-only company > schema.sql

# Include only data
pg_dump -U postgres --data-only company > data.sql

# Specific table(s)
pg_dump -U postgres --table=employees --table=departments company > tables.sql

# Compression
pg_dump -U postgres -Z 9 company > company.sql.gz

# Exclude a table
pg_dump -U postgres --exclude-table=logs company > company.sql
```



---

[← Previous](41-password-encryption.md) | [↑ Index](index.md) | [Next →](43-pgdumpall-all-databases-and-globals.md)
