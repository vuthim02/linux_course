## user@host Format

MariaDB identifies users by **username + host**:

```sql
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'pass';    -- only local socket connections
CREATE USER 'admin'@'%' IDENTIFIED BY 'pass';             -- any host
CREATE USER 'admin'@'192.168.1.%' IDENTIFIED BY 'pass';   -- subnet
CREATE USER 'admin'@'::1' IDENTIFIED BY 'pass';            -- IPv6 localhost
CREATE USER 'admin'@'db.example.com' IDENTIFIED BY 'pass'; -- specific hostname
```

**Important**: `'admin'@'localhost'` and `'admin'@'%'` are **different users**. You can have different passwords and privileges for each.



---

[← Previous](14-authentication-plugins.md) | [↑ Index](index.md) | [Next →](16-privilege-granularity.md)
