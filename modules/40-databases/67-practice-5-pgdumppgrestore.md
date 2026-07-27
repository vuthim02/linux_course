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



---

[← Previous](66-practice-4-postgresql-role-and.md) | [↑ Index](index.md) | [Next →](68-practice-6-explain-a-slow.md)
