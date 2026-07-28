## Install PostgreSQL

```bash
# Update and install
sudo apt update
sudo apt install -y postgresql postgresql-client

# Check version
psql --version

# Check status
sudo systemctl status postgresql

# Enable on boot
sudo systemctl enable postgresql
```

### What Gets Installed

| Package | Purpose |
|---------|---------|
| `postgresql` | Server and core tools |
| `postgresql-client` | `psql` CLI only (for remote connections) |
| `postgresql-contrib` | Additional extensions (pgcrypto, uuid-ossp) |

### Verifying the Installation

```bash
# The installer creates the postgres system user and starts the service
sudo -u postgres psql -c "SELECT version();"

# Check which port PostgreSQL is listening on
sudo ss -tlnp | grep 5432
```

### Key Takeaway
PostgreSQL runs as the `postgres` system user by default. All administrative tasks require `sudo -u postgres` or direct access to the postgres role.


[← Previous](27-indexing-types-in-mariadbmysql.md) | [↑ Index](index.md) | [Next →](29-initial-configuration.md)
