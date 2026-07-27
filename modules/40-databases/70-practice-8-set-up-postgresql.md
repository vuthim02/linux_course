## Practice 8: Set Up PostgreSQL Streaming Replication

```bash
# On PRIMARY (192.168.1.10):
# 1. Configure
echo -e "wal_level = replica\nmax_wal_senders = 5\nwal_keep_size = 512" | \
    sudo tee -a /etc/postgresql/16/main/conf.d/replication.conf
sudo systemctl restart postgresql

# 2. Create replication user
sudo -u postgres psql -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'rep_pass';"

# On REPLICA (192.168.1.20):
# 3. Stop PostgreSQL
sudo systemctl stop postgresql

# 4. Take base backup
sudo -u postgres pg_basebackup -h 192.168.1.10 -U replicator \
    -D /var/lib/postgresql/16/main -P -v --wal-method=stream

# 5. Create standby signal
sudo touch /var/lib/postgresql/16/main/standby.signal

# 6. Configure connection
echo "primary_conninfo = 'host=192.168.1.10 port=5432 user=replicator password=rep_pass'" | \
    sudo tee /var/lib/postgresql/16/main/postgresql.auto.conf

# 7. Start
sudo systemctl start postgresql

# 8. Check status
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```



---

[← Previous](69-practice-7-tune-buffer-sizes.md) | [↑ Index](index.md) | [Next →](71-practice-9-configure-slow-query.md)
