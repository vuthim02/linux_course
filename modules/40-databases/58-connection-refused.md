## Connection Refused

### MariaDB

```bash
# Check if MariaDB is running
sudo systemctl status mariadb

# Check bind address
sudo ss -tlnp | grep 3306

# Is it listening on all interfaces?
# If bind-address = 127.0.0.1, only local connections work

# Check firewall
sudo ufw status
sudo iptables -L -n | grep 3306

# Is the user allowed from this host?
mysql -u root -p -e "SELECT User, Host FROM mysql.user WHERE User='appuser';"

# Test connection manually
mysql -h 192.168.1.100 -u appuser -p -e "SELECT 1;"
```

### PostgreSQL

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check listening address
sudo ss -tlnp | grep 5432

# Check pg_hba.conf
sudo grep -v '^#' /etc/postgresql/16/main/pg_hba.conf | grep -v '^$'

# Test connection
psql -h localhost -U appuser -d company -c "SELECT 1;"
```



---

[← Previous](57-monitoring-tools.md) | [↑ Index](index.md) | [Next →](59-maxconnections-reached.md)
