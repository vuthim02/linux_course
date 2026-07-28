## Monitoring Tools

```bash
# Percona Toolkit (MariaDB/MySQL)
pt-query-digest /var/log/mysql/mariadb-slow.log
pt-mysql-summary
pt-variable-advisor
pt-index-usage

# pgBadger (PostgreSQL)
# Install from source or package
pgbadger /var/log/postgresql/postgresql-16-main.log

# pg_stat_statements (built-in)
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
```


# 14. Troubleshooting




[← Previous](56-postgresql-monitoring.md) | [↑ Index](index.md) | [Next →](58-connection-refused.md)
