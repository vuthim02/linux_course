## Show Commands

```sql
SHOW DATABASES;
SHOW TABLES;
SHOW TABLES FROM mysql;
SHOW COLUMNS FROM employees;
SHOW INDEX FROM employees;
SHOW CREATE TABLE employees;
SHOW PROCESSLIST;
SHOW STATUS;
SHOW VARIABLES LIKE 'innodb_buffer%';
```

### Most Useful Show Commands

| Command | What It Shows |
|---------|--------------|
| `SHOW PROCESSLIST` | Active connections and their current queries |
| `SHOW STATUS LIKE 'Threads%'` | Thread/connection counters |
| `SHOW VARIABLES LIKE 'max_connections'` | Current server configuration value |
| `SHOW ENGINE INNODB STATUS\G` | InnoDB internals: locks, buffer pool, transactions |
| `SHOW FULL PROCESSLIST` | Full query text (not truncated) |

### Pro Tips

- Use `\G` instead of `;` for vertical output — much easier to read wide rows
- `SHOW STATUS` with `LIKE` filters is your go-to for live monitoring
- `SHOW CREATE TABLE` reveals the exact DDL — useful for debugging schema mismatches


[← Previous](11-user-operations.md) | [↑ Index](index.md) | [Next →](13-example-complete-workflow.md)
