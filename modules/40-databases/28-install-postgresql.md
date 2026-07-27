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



---

[← Previous](27-indexing-types-in-mariadbmysql.md) | [↑ Index](index.md) | [Next →](29-initial-configuration.md)
