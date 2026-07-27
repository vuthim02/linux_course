## Configuration Files

```bash
# Main configuration directory (Debian/Ubuntu)
ls /etc/mysql/
#   mariadb.conf.d/   # included config snippets
#   mariadb.cnf       # main config (includes conf.d/)
#   debian.cnf        # debian-sys-maint credentials

# On RHEL/CentOS/Fedora:
ls /etc/my.cnf.d/
```

Key configuration:

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf

[mysqld]
bind-address            = 127.0.0.1
port                    = 3306
datadir                 = /var/lib/mysql
socket                  = /var/run/mysqld/mysqld.sock

# InnoDB settings
innodb_buffer_pool_size = 1G        # 70-80% of RAM for dedicated DB server
innodb_log_file_size    = 256M
innodb_flush_log_at_trx_commit = 2  # 1 = safest, 2 = faster
max_connections         = 151
```



---

[← Previous](06-run-the-secure-installation-script.md) | [↑ Index](index.md) | [Next →](08-test-the-installation.md)
