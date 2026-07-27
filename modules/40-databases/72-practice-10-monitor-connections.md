## Practice 10: Monitor Connections

```bash
# MariaDB — watch process list
watch -n 2 "sudo mysql -e 'SHOW PROCESSLIST;'"

# PostgreSQL — watch active queries
watch -n 2 "sudo -u postgres psql -c \"
  SELECT pid, usename, state, left(query, 50)
  FROM pg_stat_activity
  WHERE state != 'idle';
\""

# Simulate connections (in another terminal)
for i in $(seq 1 5); do
    mysql -u invapp -pinventory_pass -e "SELECT SLEEP(30);" &
    psql -h localhost -U invadmin -d inventory -c "SELECT pg_sleep(30);" &
done
```



---

[← Previous](71-practice-9-configure-slow-query.md) | [↑ Index](index.md) | [Next →](73-practice-11-pt-query-digest-percona-toolkit.md)
