## Test the Installation

```bash
# Connect as root using unix_socket
sudo mysql -u root

# Or with password
mysql -u root -p
```

Inside the MySQL prompt:

```sql
SHOW VARIABLES LIKE 'version';
SELECT VERSION();
SHOW DATABASES;
```

---

# 3. MariaDB Administration



---

[← Previous](07-configuration-files.md) | [↑ Index](index.md) | [Next →](09-the-mysql-cli.md)
