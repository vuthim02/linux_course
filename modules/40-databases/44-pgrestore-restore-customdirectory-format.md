## pg_restore — Restore Custom/Directory Format

```bash
# Restore custom format dump into a database
pg_restore -U postgres -d company company_backup.dump

# Create database first
createdb -U postgres newcompany
pg_restore -U postgres -d newcompany company_backup.dump

# Parallel restore (custom format only)
pg_restore -U postgres -d company -j 4 company_backup.dump

# List contents of a dump file
pg_restore -l company_backup.dump

# Restore specific table
pg_restore -U postgres -d company --table=employees company_backup.dump

# Clean (drop) objects before restoring
pg_restore -U postgres -d company --clean company_backup.dump
```



---

[← Previous](43-pgdumpall-all-databases-and-globals.md) | [↑ Index](index.md) | [Next →](45-restore-plain-sql.md)
