## MariaDB/MySQL vs PostgreSQL Commands

| Operation | MariaDB/MySQL | PostgreSQL |
|-----------|---------------|------------|
| **Connect** | `mysql -u user -p` | `psql -U user -d db` |
| **Connect as admin** | `sudo mysql` | `sudo -u postgres psql` |
| **Create database** | `CREATE DATABASE db;` | `CREATE DATABASE db;` |
| **List databases** | `SHOW DATABASES;` | `\l` or `SELECT datname FROM pg_database;` |
| **Switch database** | `USE db;` | `\c db` |
| **List tables** | `SHOW TABLES;` | `\dt` |
| **Describe table** | `DESCRIBE table;` | `\d table` |
| **Show create table** | `SHOW CREATE TABLE t;` | No direct equivalent |
| **Create user** | `CREATE USER 'u'@'h' IDENTIFIED BY 'p';` | `CREATE ROLE u LOGIN PASSWORD 'p';` |
| **List users** | `SELECT User,Host FROM mysql.user;` | `\du` or `SELECT rolname FROM pg_roles;` |
| **Grant privileges** | `GRANT ALL ON db.* TO 'u'@'h';` | `GRANT ALL ON DATABASE db TO u;` |
| **Show grants** | `SHOW GRANTS FOR 'u'@'h';` | `\du+` or `SELECT * FROM information_schema.applicable_roles;` |
| **Revoke privileges** | `REVOKE ALL ON db.* FROM 'u'@'h';` | `REVOKE ALL ON DATABASE db FROM u;` |
| **Change password** | `ALTER USER 'u'@'h' IDENTIFIED BY 'p';` | `ALTER ROLE u WITH PASSWORD 'p';` |
| **Backup (single DB)** | `mysqldump db > file.sql` | `pg_dump db > file.sql` |
| **Backup (all DBs)** | `mysqldump --all-databases > file.sql` | `pg_dumpall > file.sql` |
| **Restore (SQL file)** | `mysql db < file.sql` | `psql db < file.sql` |
| **Restore (custom)** | N/A | `pg_restore -d db file.dump` |
| **Check connections** | `SHOW PROCESSLIST;` | `SELECT * FROM pg_stat_activity;` |
| **Kill query** | `KILL id;` | `SELECT pg_cancel_backend(pid);` |
| **Explain query** | `EXPLAIN SELECT ...;` | `EXPLAIN ANALYZE SELECT ...;` |
| **Set variable** | `SET GLOBAL var = val;` | `ALTER SYSTEM SET var = 'val';` |
| **Show config** | `SHOW VARIABLES LIKE '%buf%';` | `SHOW shared_buffers;` |
| **Transaction** | `BEGIN; ... COMMIT;` | `BEGIN; ... COMMIT;` |
| **Auto-increment** | `INT AUTO_INCREMENT` | `SERIAL` or `IDENTITY` |
| **String concat** | `CONCAT(a, b)` | `a || b` |
| **Limit rows** | `LIMIT n` | `LIMIT n` (or `FETCH FIRST n ROWS ONLY`) |
| **Offset** | `LIMIT n OFFSET m` | `LIMIT n OFFSET m` |
| **ILIKE (case-insensitive)** | `LIKE` (lowercase both sides) | `ILIKE` |
| **JSON support** | `JSON` type (MySQL 5.7+) | `JSONB` (superior indexing) |
| **Full-text search** | `FULLTEXT index, MATCH ... AGAINST` | `GIN index, tsvector/tsquery` |
| **Vacuum** | Not needed (MVCC via undo logs) | `VACUUM`, `VACUUM FULL` |
| **Analyze** | `ANALYZE TABLE t;` | `ANALYZE;` or `VACUUM ANALYZE;` |
| **Configuration file** | `/etc/mysql/mariadb.conf.d/` | `/etc/postgresql/16/main/postgresql.conf` |
| **Auth config file** | MySQL grants in `mysql.user` | `/etc/postgresql/16/main/pg_hba.conf` |
| **Default port** | 3306 | 5432 |
| **Data directory** | `/var/lib/mysql` | `/var/lib/postgresql/16/main` |
| **Log directory** | `/var/log/mysql/` | `/var/log/postgresql/` |
| **Connection model** | Thread-per-connection | Process-per-connection |
| **Storage engine** | Pluggable (InnoDB, MyISAM, etc.) | Built-in (heap-based, MVCC) |
| **Replication** | Async, semi-sync, GTID | Streaming, logical, synchronous |
| **Docker image** | `mariadb:latest` | `postgres:latest` |


# 🔮 What's Coming in Part 41

**Part 41: LDAP and Centralized Authentication**

We'll cover:
- LDAP concepts (DIT, entries, attributes, DN, RDN, OU)
- OpenLDAP installation and configuration
- slapd, slapcat, ldapadd, ldapsearch
- LDAP Authentication (pam_ldap, nss_ldap)
- Migrating local users to LDAP
- LDAP over TLS
- SSSD and Active Directory integration
- FreeIPA overview


# ✅ Self-Test

**Score:** 12/15 correct = ready for Part 41.

1. What is the main difference between `unix_socket` authentication (MariaDB) and `peer` authentication (PostgreSQL)?

2. Write the command to create a MariaDB user `webapp` that can connect from any host with password `Str0ng!`.

3. Write the equivalent PostgreSQL command to create a role `webapp` that can log in with password `Str0ng!`.

4. What does `--single-transaction` do in mysqldump, and why is it important?

5. What is the PostgreSQL equivalent of `SHOW PROCESSLIST;` in MariaDB?

6. Explain the difference between `pg_dump -Fc` (custom format) and plain SQL format.

7. What is the purpose of `innodb_buffer_pool_size`? What percentage of RAM is recommended?

8. What is the PostgreSQL equivalent of `innodb_buffer_pool_size`?

9. You run `EXPLAIN ANALYZE` on a query and see `Seq Scan` on a 10-million-row table. What's the likely problem and fix?

10. A MariaDB replica shows `Slave_IO_Running: No`. List three possible causes and how to investigate each.

11. What does WAL stand for and why is it essential for database durability?

12. How does MVCC (Multi-Version Concurrency Control) allow concurrent reads and writes without blocking?

13. In PostgreSQL, what is the difference between `pg_cancel_backend()` and `pg_terminate_backend()`?

14. Write a command to backup all MariaDB databases with routines and compress the output.

15. Write a PostgreSQL command to restore a custom-format dump `/tmp/db.dump` into database `mydb` using 4 parallel jobs.

**Answers:**

**1.** `unix_socket` authenticates by checking the Unix user's UID against the MariaDB user (root → root, no password needed). `peer` authenticates by matching the connecting OS user to the PostgreSQL role name (e.g., OS user `postgres` → DB role `postgres`). Both rely on the OS, not a password, but `unix_socket` doesn't require the usernames to match (it verifies the process's UID).

**2.** `CREATE USER 'webapp'@'%' IDENTIFIED BY 'Str0ng!';`

**3.** `CREATE ROLE webapp WITH LOGIN PASSWORD 'Str0ng!';`

**4.** `--single-transaction` wraps the entire dump in a single transaction, using InnoDB's MVCC to get a consistent snapshot without locking tables. This is critical for live databases — readers and writers are not blocked during the backup.

**5.** `SELECT * FROM pg_stat_activity;` (or `\du` in psql for users). In MariaDB: `SHOW PROCESSLIST;`.

**6.** Plain SQL (`pg_dump db > file.sql`) produces a large SQL script that can be read and edited. Custom format (`-Fc`) produces a compressed, binary file that supports parallel restore (`-j`), selective restore (`-t table`), and is generally faster for larger databases.

**7.** `innodb_buffer_pool_size` is the memory cache for InnoDB data and indexes. On a dedicated database server, 70-80% of RAM is recommended.

**8.** `shared_buffers` — typically set to 25% of RAM (not 70-80%, because PostgreSQL relies on the OS page cache too).

**9.** A `Seq Scan` (sequential/full table scan) on a 10M-row table means the query is reading every row. The fix is to add an appropriate index (e.g., `CREATE INDEX ON table(column)` for the column being filtered in `WHERE`).

**10.** (1) Network issue — ping/telnet to the primary; (2) authentication failure — check `Last_IO_Error`; (3) primary's binary log position no longer available — the binary log was purged before the replica read it, resync with `CHANGE MASTER TO`.

**11.** **WAL** = Write-Ahead Log. Before any change is written to the data files, it is first written to the WAL. On crash recovery, the database replays the WAL to reconstruct any committed transactions that weren't yet written to data files. This guarantees **durability** (the D in ACID).

**12.** MVCC works by keeping multiple versions of each row. When a row is updated, the old version is preserved in an **undo log** (MariaDB) or in the table itself (PostgreSQL). Each transaction sees the database as of its snapshot time. Readers never block writers and writers never block readers — they see different versions of the same row.

**13.** `pg_cancel_backend()` sends a cancel signal (interrupts the current query but keeps the connection open). `pg_terminate_backend()` terminates the entire backend process (kills the connection). Use cancel first; if it doesn't work, terminate.

**14.** `mysqldump -u root -p --all-databases --single-transaction --routines --events --triggers | gzip > full_backup.sql.gz`

**15.** `pg_restore -U postgres -d mydb -j 4 /tmp/db.dump`


# 📚 Footer

```
Previous → Part 39: Web Servers
Next → Part 41: LDAP and Centralized Authentication
```


*"A database is only as reliable as its backup strategy, and only as fast as its slowest query."*

[← Previous](part39.md) | [Next →](part41.md)



[← Previous](79-postgresql-process-architecture.md) | [↑ Index](index.md)
