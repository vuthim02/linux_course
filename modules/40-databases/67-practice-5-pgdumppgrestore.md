## Practice 5: pg_dump/pg_restore

```bash
# 1. Backup
pg_dump -U invadmin -h localhost -Fc inventory > /tmp/inventory.dump

# 2. Drop and recreate
sudo -u postgres psql -c "DROP DATABASE inventory;"
sudo -u postgres psql -c "CREATE DATABASE inventory OWNER invadmin;"

# 3. Restore
pg_restore -U invadmin -h localhost -d inventory /tmp/inventory.dump

# 4. Verify
psql -U invadmin -h localhost -d inventory -c "SELECT * FROM items;"
```

### Understanding -Fc (Custom Format)

| Flag | Meaning |
|------|---------|
| `-F` | Output format |
| `c` | Custom (compressed, supports parallel restore) |
| `-f` | Output file |

### Why Custom Format Over Plain SQL?

- **Compression**: Custom format is typically 3-5x smaller
- **Selective restore**: `pg_restore -t items inventory.dump` (restore only one table)
- **Parallel restore**: `pg_restore -j 4 -d inventory inventory.dump` (use 4 workers)
- **No re-execution of DDL**: Handles dependencies correctly


[← Previous](66-practice-4-postgresql-role-and.md) | [↑ Index](index.md) | [Next →](68-practice-6-explain-a-slow.md)
