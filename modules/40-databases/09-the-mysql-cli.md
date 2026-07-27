## The mysql CLI

```bash
# Connect to local socket
mysql -u root -p

# Connect to remote host
mysql -h 192.168.1.100 -P 3306 -u admin -p

# Execute a single command
mysql -u root -p -e "SHOW DATABASES;"

# Source a SQL file
mysql -u root -p < /tmp/backup.sql
```



---

[← Previous](08-test-the-installation.md) | [↑ Index](index.md) | [Next →](10-database-operations.md)
