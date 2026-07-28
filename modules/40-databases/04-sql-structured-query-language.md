## SQL (Structured Query Language)

SQL is the language for talking to relational databases. Four main categories:

| Category | Purpose | Examples |
|----------|---------|---------|
| **DDL** | Define structure | `CREATE`, `ALTER`, `DROP` |
| **DML** | Manipulate data | `SELECT`, `INSERT`, `UPDATE`, `DELETE` |
| **DCL** | Control access | `GRANT`, `REVOKE` |
| **TCL** | Control transactions | `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT` |

### Quick Example

```sql
-- DDL: create a table
CREATE TABLE users (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(100), email VARCHAR(255) UNIQUE);

-- DML: insert and query
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');
SELECT name, email FROM users WHERE name LIKE 'A%';

-- TCL: transaction
BEGIN;
UPDATE users SET email = 'alice@newdomain.com' WHERE id = 1;
COMMIT;
```

### MariaDB vs PostgreSQL SQL Differences

| Feature | MariaDB | PostgreSQL |
|---------|---------|------------|
| Auto-increment | `AUTO_INCREMENT` | `SERIAL` / `GENERATED ALWAYS AS IDENTITY` |
| UPSERT | `INSERT ... ON DUPLICATE KEY UPDATE` | `INSERT ... ON CONFLICT DO UPDATE` |
| String concat | `CONCAT()` | `\|\|` operator |
| Limit syntax | `LIMIT n` | `LIMIT n` (also supports `FETCH FIRST n ROWS ONLY`) |


# 2. MariaDB/MySQL Installation


[← Previous](03-relational-vs-nosql.md) | [↑ Index](index.md) | [Next →](05-install-mariadb-server.md)
