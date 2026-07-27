## User Operations

```sql
-- Show all users
SELECT User, Host, plugin FROM mysql.user;

-- Create a user
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'strong_password';
CREATE USER 'appuser'@'%' IDENTIFIED BY 'strong_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON company.* TO 'appuser'@'localhost';
GRANT SELECT, INSERT, UPDATE ON company.* TO 'readwrite'@'%';
GRANT SELECT ON company.* TO 'readonly'@'%';

-- Grant with option to grant to others
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;

-- Revoke privileges
REVOKE DELETE ON company.* FROM 'appuser'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- Drop a user
DROP USER 'appuser'@'localhost';

-- Change password
ALTER USER 'appuser'@'localhost' IDENTIFIED BY 'new_password';
```



---

[← Previous](10-database-operations.md) | [↑ Index](index.md) | [Next →](12-show-commands.md)
