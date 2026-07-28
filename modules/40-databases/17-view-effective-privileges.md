## View Effective Privileges

```sql
-- Show grants for current user
SHOW GRANTS;

-- Show grants for specific user
SHOW GRANTS FOR 'appuser'@'localhost';
```

### Understanding the Output

`SHOW GRANTS` returns the exact `GRANT` statements that define a user's privileges:

```sql
+-----------------------------------------------------+
| Grants for appuser@localhost                         |
+-----------------------------------------------------+
| GRANT USAGE ON *.* TO 'appuser'@'localhost'          |
| GRANT SELECT, INSERT, UPDATE ON company.* TO ...     |
+-----------------------------------------------------+
```

- `USAGE` = no global privileges (login only)
- `SELECT, INSERT, UPDATE ON company.*` = full access to all tables in the `company` database
- Missing `DELETE` or `DROP` means the user cannot remove data or objects

### Checking Privileges for Other Users (Requires SUPER)

```sql
-- As root or a user with SHOW DATABASES privilege
SELECT user, host FROM mysql.user;
SHOW GRANTS FOR 'admin'@'192.168.1.%';
```


[← Previous](16-privilege-granularity.md) | [↑ Index](index.md) | [Next →](18-best-practices.md)
