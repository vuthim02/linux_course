## Practice 7: Tune Buffer Sizes

```bash
# 1. Check current MariaDB buffer pool size
sudo mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# 2. Calculate 70% of system RAM
free -g

# 3. Update MariaDB config
echo -e "[mysqld]\ninnodb_buffer_pool_size = 1G" | \
    sudo tee /etc/mysql/mariadb.conf.d/99-tuning.cnf
sudo systemctl restart mariadb

# 4. Verify new setting
sudo mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# 5. Same for PostgreSQL
echo -e "shared_buffers = 512MB\neffective_cache_size = 2GB" | \
    sudo tee /etc/postgresql/16/main/conf.d/tuning.conf
sudo systemctl restart postgresql
sudo -u postgres psql -c "SHOW shared_buffers;"
sudo -u postgres psql -c "SHOW effective_cache_size;"
```



---

[← Previous](68-practice-6-explain-a-slow.md) | [↑ Index](index.md) | [Next →](70-practice-8-set-up-postgresql.md)
