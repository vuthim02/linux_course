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

### Connection Priority

When a client connects, MariaDB matches in this order:
1. Exact host match (e.g., `db.example.com`)
2. Exact IP match (e.g., `192.168.1.10`)
3. Netmask match (e.g., `192.168.1.%`)
4. `%` wildcard

### Best Practice

```sql
-- Secure: only allow from specific subnet with strong password
CREATE USER 'appuser'@'192.168.1.%' IDENTIFIED BY 'secure_password';

-- Never do this in production:
CREATE USER 'admin'@'%' IDENTIFIED BY 'weak';
```


[← Previous](14-authentication-plugins.md) | [↑ Index](index.md) | [Next →](16-privilege-granularity.md)
