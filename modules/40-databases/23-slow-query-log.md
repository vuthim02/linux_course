## Slow Query Log

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mariadb-slow.log
long_query_time = 2          # seconds — log queries slower than this
log_queries_not_using_indexes = 1
min_examined_row_limit = 100
```

```bash
# View slow queries
sudo tail -f /var/log/mysql/mariadb-slow.log

# Analyze slow query log with mysqldumpslow
mysqldumpslow /var/log/mysql/mariadb-slow.log
```




[← Previous](22-explain-query-execution-plan.md) | [↑ Index](index.md) | [Next →](24-innodb-buffer-pool.md)
