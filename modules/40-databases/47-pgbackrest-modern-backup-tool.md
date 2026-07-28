## pgBackRest (Modern Backup Tool)

```bash
# Install
sudo apt install -y pgbackrest

# Configure
# /etc/pgbackrest/pgbackrest.conf
# [mydb]
# pg1-path=/var/lib/postgresql/16/main
# repo1-path=/var/backups/pgbackrest
# repo1-type=posix

# Create a backup
sudo -u postgres pgbackrest --stanza=mydb --type=full backup

# List backups
sudo -u postgres pgbackrest --stanza=mydb info

# Restore
sudo systemctl stop postgresql
sudo -u postgres pgbackrest --stanza=mydb --delta restore
sudo systemctl start postgresql
```


# 11. PostgreSQL Performance




[← Previous](46-wal-archiving-continuous-archiving.md) | [↑ Index](index.md) | [Next →](48-explain-analyze.md)
