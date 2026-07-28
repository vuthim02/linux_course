## Table Operations

```sql
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    department_id INTEGER REFERENCES departments(id),
    salary NUMERIC(10,2) DEFAULT 0.00,
    hired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Show table structure
\d employees

-- Show table with comments
\d+ employees

-- Drop table
DROP TABLE employees;
```




[← Previous](34-database-operations.md) | [↑ Index](index.md) | [Next →](36-role-user-operations.md)
