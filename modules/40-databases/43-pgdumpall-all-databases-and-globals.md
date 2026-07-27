## pg_dumpall — All Databases and Globals

```bash
# Dump all databases + roles + tablespaces
pg_dumpall -U postgres > all_databases.sql

# Roles only (for migrations)
pg_dumpall -U postgres --roles-only > roles.sql

# Schema only across all databases
pg_dumpall -U postgres --schema-only > all_schema.sql
```



---

[← Previous](42-pgdump-single-database-backup.md) | [↑ Index](index.md) | [Next →](44-pgrestore-restore-customdirectory-format.md)
