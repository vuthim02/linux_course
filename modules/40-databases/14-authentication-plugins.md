## Authentication Plugins

MariaDB supports multiple authentication methods:

| Plugin | Description | Default in |
|--------|-------------|------------|
| `unix_socket` | Authenticate via OS user (no password) | MariaDB 10.4+ (root) |
| `mysql_native_password` | Legacy password hash | Older MySQL/MariaDB |
| `caching_sha2_password` | SHA-256 with caching | MySQL 8.0+ |
| `ed25519` | Public-key crypto | MariaDB 10.4+ |
| `pam` | PAM integration | Enterprise |

Check current root plugin:

```sql
SELECT User, Host, plugin FROM mysql.user WHERE User='root';
```

If root uses `unix_socket`, only `sudo mysql` works (no password needed).




[← Previous](13-example-complete-workflow.md) | [↑ Index](index.md) | [Next →](15-userhost-format.md)
