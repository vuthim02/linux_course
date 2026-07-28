## Practice 9: Configure Slow Query Log

```bash
# MariaDB
echo -e "[mysqld]\nslow_query_log = 1\nslow_query_log_file = /var/log/mysql/slow.log\nlong_query_time = 1" | \
    sudo tee /etc/mysql/mariadb.conf.d/99-slow-log.conf
sudo systemctl restart mariadb

# Generate a slow query
sudo mysql -e "SELECT BENCHMARK(50000000, MD5('test'));"

# Check the slow log
sudo tail -5 /var/log/mysql/slow.log

# PostgreSQL
echo -e "log_min_duration_statement = 1000\nlog_statement = 'ddl'\nlog_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h'" | \
    sudo tee /etc/postgresql/16/main/conf.d/logging.conf
sudo systemctl restart postgresql

# Generate a slow query
sudo -u postgres psql -d inventory -c "SELECT pg_sleep(2);"

# Check the log
sudo tail /var/log/postgresql/postgresql-16-main.log
```




[← Previous](70-practice-8-set-up-postgresql.md) | [↑ Index](index.md) | [Next →](72-practice-10-monitor-connections.md)
