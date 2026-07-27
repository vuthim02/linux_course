## Practice 13: Database Size Monitoring

```bash
# MariaDB
sudo mysql << 'SQL'
SELECT table_schema AS db,
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.TABLES
GROUP BY table_schema
ORDER BY size_mb DESC;
SQL

# PostgreSQL
sudo -u postgres psql << 'SQL'
SELECT datname,
       pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;
SQL
```



---

[← Previous](74-practice-12-troubleshoot-a-stuck.md) | [↑ Index](index.md) | [Next →](76-practice-14-point-in-time-recovery.md)
