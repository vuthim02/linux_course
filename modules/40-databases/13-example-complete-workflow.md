## Example: Complete Workflow

```bash
# 1. Connect as root
sudo mysql

# 2. Create database
CREATE DATABASE shop CHARACTER SET utf8mb4;

# 3. Create user
CREATE USER 'shopadmin'@'localhost' IDENTIFIED BY 'secret123';
GRANT ALL PRIVILEGES ON shop.* TO 'shopadmin'@'localhost';
FLUSH PRIVILEGES;

# 4. Create tables as shopadmin
mysql -u shopadmin -p shop

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0
);

CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    ordered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO products (name, price, stock) VALUES
    ('Widget', 9.99, 100),
    ('Gadget', 24.99, 50),
    ('Doohickey', 4.99, 200);

SELECT * FROM products;
```

---

# 4. MariaDB User Management — Deep Dive



---

[← Previous](12-show-commands.md) | [↑ Index](index.md) | [Next →](14-authentication-plugins.md)
