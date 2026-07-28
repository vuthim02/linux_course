## Practice 2: Create Database and User

```bash
# 1. Create a database
sudo mysql -e "CREATE DATABASE inventory CHARACTER SET utf8mb4;"

# 2. Create an application user
sudo mysql -e "
CREATE USER 'invapp'@'localhost' IDENTIFIED BY 'inventory_pass';
GRANT ALL PRIVILEGES ON inventory.* TO 'invapp'@'localhost';
FLUSH PRIVILEGES;
"

# 3. Create tables
mysql -u invapp -pinventory_pass inventory << 'SQL'
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);
CREATE TABLE items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category_id INT,
    quantity INT DEFAULT 0,
    price DECIMAL(10,2),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);
INSERT INTO categories (name) VALUES ('Electronics'), ('Books'), ('Clothing');
INSERT INTO items (name, category_id, quantity, price) VALUES
    ('Laptop', 1, 10, 999.99),
    ('Python Book', 2, 50, 39.99),
    ('T-Shirt', 3, 200, 14.99);
SQL

# 4. Verify
mysql -u invapp -pinventory_pass -e "SELECT * FROM inventory.items;"
```




[← Previous](63-practice-1-secure-mariadb-installation.md) | [↑ Index](index.md) | [Next →](65-practice-3-mysqldump-backup-and.md)
