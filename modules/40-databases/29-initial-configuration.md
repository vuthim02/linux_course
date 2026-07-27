## Initial Configuration

PostgreSQL creates a `postgres` system user and a `postgres` database role:

```bash
# Connect as postgres (via peer auth)
sudo -u postgres psql

# Set a password for the postgres role
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'newpassword';"
```



---

[← Previous](28-install-postgresql.md) | [↑ Index](index.md) | [Next →](30-configuration-files.md)
