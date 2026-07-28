## Initial Configuration

PostgreSQL creates a `postgres` system user and a `postgres` database role:

```bash
# Connect as postgres (via peer auth)
sudo -u postgres psql

# Set a password for the postgres role
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'newpassword';"
```

### Verify the Installation

```bash
# Check PostgreSQL version
sudo -u postgres psql -c "SELECT version();"

# List databases
sudo -u postgres psql -c "\l"

# Check listening addresses
sudo -u postgres psql -c "SHOW listen_addresses;"
```

### Common Post-Install Steps

1. **Enable remote connections** in `postgresql.conf`: `listen_addresses = '*'`
2. **Create an application role**: `CREATE ROLE appuser WITH LOGIN PASSWORD 'securepass';`
3. **Create your first database**: `CREATE DATABASE myapp OWNER appuser;`
4. **Test connectivity**: `psql -h localhost -U appuser -d myapp`

### Key Takeaway
Always set a password for the `postgres` role immediately. The default `peer` authentication is secure for local use but doesn't help when applications connect over TCP.


[← Previous](28-install-postgresql.md) | [↑ Index](index.md) | [Next →](30-configuration-files.md)
