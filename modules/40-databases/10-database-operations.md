## Database Operations

```sql
-- Show all databases
SHOW DATABASES;

-- Create a database
CREATE DATABASE company;
CREATE DATABASE IF NOT EXISTS company CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Use (select) a database
USE company;

-- Show tables in current database
SHOW TABLES;

-- Create a table
CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    department_id INT,
    salary DECIMAL(10,2) DEFAULT 0.00,
    hired_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

-- Show table structure
DESCRIBE employees;
SHOW CREATE TABLE employees;

-- Drop a table
DROP TABLE employees;

-- Drop a database (CAREFUL!)
DROP DATABASE company;
```




[← Previous](09-the-mysql-cli.md) | [↑ Index](index.md) | [Next →](11-user-operations.md)
