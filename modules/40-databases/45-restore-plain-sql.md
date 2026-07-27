## Restore Plain SQL

```bash
# Restore a plain SQL dump
psql -U postgres -f company_backup.sql

# To a specific database
psql -U postgres -d company < company_backup.sql
```



---

[← Previous](44-pgrestore-restore-customdirectory-format.md) | [↑ Index](index.md) | [Next →](46-wal-archiving-continuous-archiving.md)
