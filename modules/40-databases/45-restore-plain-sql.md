## Restore Plain SQL

```bash
# Restore a plain SQL dump
psql -U postgres -f company_backup.sql

# To a specific database
psql -U postgres -d company < company_backup.sql
```

### When to Use Plain SQL vs Custom Format

| Format | Command | Use Case |
|--------|---------|----------|
| Plain SQL (`-Fp`) | `psql -f` | Small databases, human-readable, cross-version |
| Custom (`-Fc`) | `pg_restore -d` | Large databases, selective restore, parallel jobs |
| Directory (`-Fd`) | `pg_restore -d` | Parallel restore, table-level selection |
| Tar (`-Ft`) | `pg_restore -d` | Single-file archive with compression |

### Common Pitfalls

- **Owner mismatch**: The restoring user must have permission to create objects. Use `--no-owner` if the original owner doesn't exist.
- **Encoding**: Plain SQL dumps are in the source database encoding. Use `SET client_encoding = 'UTF8';` if restoring to a differently-encoded server.
- **Sequence values**: After restoring, reset sequences: `SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));`


[← Previous](44-pgrestore-restore-customdirectory-format.md) | [↑ Index](index.md) | [Next →](46-wal-archiving-continuous-archiving.md)
