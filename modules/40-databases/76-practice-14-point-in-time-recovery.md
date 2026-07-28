## Practice 14: Point-in-Time Recovery

```bash
# 1. Enable binary logging on MariaDB
echo -e "[mysqld]\nlog_bin = /var/log/mysql/bin-log" | \
    sudo tee /etc/mysql/mariadb.conf.d/99-binlog.conf
sudo systemctl restart mariadb

# 2. Create a backup
mysqldump -u root -p --all-databases --single-transaction --master-data=2 > /tmp/full.sql

# 3. Make some changes
sudo mysql -e "CREATE DATABASE testpitr; USE testpitr; CREATE TABLE t (id INT); INSERT INTO t VALUES (1);"

# 4. Note the time
date '+%Y-%m-%d %H:%M:%S'

# 5. Make more changes
sudo mysql -e "INSERT INTO testpitr.t VALUES (2);"

# 6. Restore to before the second change
sudo mysql -u root -p < /tmp/full.sql
mysqlbinlog --stop-datetime="<time_from_step_4>" /var/log/mysql/bin-log.* | sudo mysql -u root -p

# 7. Verify
sudo mysql -e "SELECT * FROM testpitr.t;"  # Should only show id=1
```




[← Previous](75-practice-13-database-size-monitoring.md) | [↑ Index](index.md) | [Next →](77-practice-15-real-world-integration-complete.md)
