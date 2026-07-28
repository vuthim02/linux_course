## Install MariaDB Server

```bash
# Update package index
sudo apt update

# Install MariaDB server and client
sudo apt install -y mariadb-server mariadb-client

# Check status
sudo systemctl status mariadb

# Enable on boot (usually auto-enabled)
sudo systemctl enable mariadb

# Verify version
mysql --version
mariadb --version   # same binary
```




[← Previous](04-sql-structured-query-language.md) | [↑ Index](index.md) | [Next →](06-run-the-secure-installation-script.md)
