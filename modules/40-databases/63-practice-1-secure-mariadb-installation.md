## Practice 1: Secure MariaDB Installation

```bash
# 1. Install MariaDB
sudo apt update && sudo apt install -y mariadb-server

# 2. Run secure installation
sudo mysql_secure_installation

# 3. Verify no anonymous users
sudo mysql -e "SELECT User, Host FROM mysql.user WHERE User='';"

# 4. Verify test database is gone
sudo mysql -e "SHOW DATABASES;" | grep test

# 5. Verify root cannot connect remotely
sudo mysql -e "SELECT User, Host FROM mysql.user WHERE User='root' AND Host != 'localhost';"
```



---

[← Previous](62-lock-waits-and-deadlocks.md) | [↑ Index](index.md) | [Next →](64-practice-2-create-database-and.md)
