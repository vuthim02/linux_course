## pg_dumpall — All Databases and Globals

```bash
# Dump all databases + roles + tablespaces
pg_dumpall -U postgres > all_databases.sql

# Roles only (for migrations)
pg_dumpall -U postgres --roles-only > roles.sql

# Schema only across all databases
pg_dumpall -U postgres --schema-only > all_schema.sql
```

### pg_dumpall vs pg_dump

| Feature | `pg_dumpall` | `pg_dump` |
|---------|-------------|-----------|
| Scope | All databases | Single database |
| Globals | Yes (roles, tablespaces) | No |
| Output format | Plain SQL only | Custom, tar, directory, plain SQL |
| Parallel restore | No | Yes (`-j`) |
| Selective restore | No | Yes (`-t table`) |

### Restoring with pg_dumpall

```bash
# Restore everything (run as postgres)
psql -U postgres -f all_databases.sql

# Restore only roles (useful when migrating databases one by one)
psql -U postgres -f roles.sql
```

### Key Takeaway
Always run `pg_dumpall --roles-only` before migrating databases — roles and permissions are often forgotten when you only restore individual databases with `pg_dump`.


[← Previous](42-pgdump-single-database-backup.md) | [↑ Index](index.md) | [Next →](44-pgrestore-restore-customdirectory-format.md)
