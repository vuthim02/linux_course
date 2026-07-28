## Relational Databases (RDBMS)

A **relational database** organizes data into **tables** (relations) with **rows** (records) and **columns** (fields). Tables relate to each other via **keys**.

| Concept | Description | Real example |
|---------|-------------|--------------|
| **Schema** | The structure — defines tables, columns, types, constraints | `CREATE TABLE users (id INT, name VARCHAR(100));` |
| **Table** | A collection of rows with the same columns | `users`, `orders`, `products` |
| **Row** | A single record in a table | One user's data |
| **Column** | A named field with a data type | `id INT`, `email VARCHAR(255)` |
| **Primary Key** | Uniquely identifies each row | `id INT PRIMARY KEY AUTO_INCREMENT` |
| **Foreign Key** | Links rows across tables | `user_id INT REFERENCES users(id)` |
| **Index** | Accelerates lookups | `CREATE INDEX idx_email ON users(email);` |
| **Transaction** | Group of operations, all or nothing | `BEGIN; UPDATE ...; COMMIT;` |

### Popular RDBMS Options

| Database | License | Best For |
|----------|---------|----------|
| **MariaDB** | GPL | Drop-in MySQL replacement, web apps |
| **PostgreSQL** | PostgreSQL License | Complex queries, GIS, JSONB, extensibility |
| **MySQL** | GPL + Commercial | Web applications, widespread hosting support |
| **SQLite** | Public Domain | Embedded, mobile, testing, single-file databases |


[↑ Index](index.md) | [Next →](02-acid-properties.md)
