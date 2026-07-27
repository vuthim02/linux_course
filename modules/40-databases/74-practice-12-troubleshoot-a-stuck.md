## Practice 12: Troubleshoot a Stuck Query

```bash
# 1. Start a long transaction
mysql -u invapp -pinventory_pass -e "BEGIN; UPDATE inventory.items SET quantity = quantity - 1 WHERE id = 1; SELECT SLEEP(60); COMMIT;" &

# 2. In another terminal, find and kill it
sudo mysql -e "SHOW PROCESSLIST;"
sudo mysql -e "KILL <thread_id>;"

# Same for PostgreSQL
psql -h localhost -U invadmin -d inventory -c "BEGIN; UPDATE items SET quantity = quantity - 1 WHERE id = 1; SELECT pg_sleep(60); COMMIT;" &
sudo -u postgres psql -c "SELECT pid, query FROM pg_stat_activity WHERE state = 'active';"
sudo -u postgres psql -c "SELECT pg_cancel_backend(<pid>);"
```



---

[← Previous](73-practice-11-pt-query-digest-percona-toolkit.md) | [↑ Index](index.md) | [Next →](75-practice-13-database-size-monitoring.md)
