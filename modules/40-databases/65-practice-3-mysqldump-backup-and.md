## Practice 3: mysqldump Backup and Restore

```bash
# 1. Create a full backup
mysqldump -u invapp -pinventory_pass \
    --single-transaction \
    --routines \
    inventory > /tmp/inventory_backup.sql

# 2. Drop the database
sudo mysql -e "DROP DATABASE inventory;"

# 3. Restore
sudo mysql -e "CREATE DATABASE inventory;"
mysql -u invapp -pinventory_pass inventory < /tmp/inventory_backup.sql

# 4. Verify data integrity
mysql -u invapp -pinventory_pass -e "SELECT COUNT(*) FROM inventory.items;"
```




[← Previous](64-practice-2-create-database-and.md) | [↑ Index](index.md) | [Next →](66-practice-4-postgresql-role-and.md)
