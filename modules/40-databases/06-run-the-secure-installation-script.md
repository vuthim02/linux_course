## Run the Secure Installation Script

```bash
sudo mysql_secure_installation
```

This script:
- Sets the root password (or switches to unix_socket authentication)
- Removes anonymous users
- Disallows remote root login
- Removes the `test` database
- Reloads privilege tables

Walkthrough:

```
Enter current password for root (enter for none):  [Enter]
Switch to unix_socket authentication [Y/n]: Y
Change the root password? [Y/n]: n
Remove anonymous users? [Y/n]: Y
Disallow root login remotely? [Y/n]: Y
Remove test database and access to it? [Y/n]: Y
Reload privilege tables now? [Y/n]: Y
```




[← Previous](05-install-mariadb-server.md) | [↑ Index](index.md) | [Next →](07-configuration-files.md)
