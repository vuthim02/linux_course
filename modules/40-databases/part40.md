# 🐧 Linux System Administrator — Complete Course
## Part 40 of ∞: Databases — MariaDB, MySQL, and PostgreSQL

---

# 🎯 Reverse Engineering Approach

In each part of this course, we use the **Reverse Engineering Approach**: instead of memorizing abstract theory, you start with a **running system**, break it apart, change it, break it, and fix it — until you deeply understand how it works.

For databases, this means:
1. Install both MariaDB and PostgreSQL
2. Create real databases, tables, users
3. Break replication, fix it
4. Write backup scripts, test restores
5. Tune configuration, observe the effects
6. Only then — understand the internals

---

# 1. Database Concepts

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

## ACID Properties

Relational databases guarantee **ACID**:

- **Atomicity** — a transaction completes fully or not at all (no partial writes)
- **Consistency** — data always satisfies constraints (foreign keys, types, CHECK)
- **Isolation** — concurrent transactions don't interfere (controlled by isolation level)
- **Durability** — committed data survives crashes (thanks to **WAL** — Write-Ahead Log)

## Relational vs NoSQL

| Aspect | RDBMS (MariaDB/PostgreSQL) | NoSQL (MongoDB, Redis) |
|--------|---------------------------|------------------------|
| Data model | Tables, rows, columns | Documents, key-value, graphs |
| Schema | Fixed (enforced) | Flexible (schema-less) |
| Joins | Native, powerful | Manual or limited |
| ACID | Full | Often BASE (eventually consistent) |
| Scaling | Vertical (scale up) | Horizontal (scale out) |
| Use case | Financial, structured data | Real-time feeds, big data, caching |

## SQL (Structured Query Language)

SQL is the language for talking to relational databases. Four main categories:

| Category | Purpose | Examples |
|----------|---------|---------|
| **DDL** | Define structure | `CREATE`, `ALTER`, `DROP` |
| **DML** | Manipulate data | `SELECT`, `INSERT`, `UPDATE`, `DELETE` |
| **DCL** | Control access | `GRANT`, `REVOKE` |
| **TCL** | Control transactions | `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT` |

---

# 2. MariaDB/MySQL Installation

## Install MariaDB Server

```bash
# Update package index
sudo apt update

# Install MariaDB server and client
sudo apt install -y mariadb-server mariadb-client

# Check status
sudo systemctl status mariadb

# Enable on boot (usually auto-enabled)
sudo systemctl enable mariadb

# Verify version
mysql --version
mariadb --version   # same binary
```

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

## Configuration Files

```bash
# Main configuration directory (Debian/Ubuntu)
ls /etc/mysql/
#   mariadb.conf.d/   # included config snippets
#   mariadb.cnf       # main config (includes conf.d/)
#   debian.cnf        # debian-sys-maint credentials

# On RHEL/CentOS/Fedora:
ls /etc/my.cnf.d/
```

Key configuration:

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf

[mysqld]
bind-address            = 127.0.0.1
port                    = 3306
datadir                 = /var/lib/mysql
socket                  = /var/run/mysqld/mysqld.sock

# InnoDB settings
innodb_buffer_pool_size = 1G        # 70-80% of RAM for dedicated DB server
innodb_log_file_size    = 256M
innodb_flush_log_at_trx_commit = 2  # 1 = safest, 2 = faster
max_connections         = 151
```

## Test the Installation

```bash
# Connect as root using unix_socket
sudo mysql -u root

# Or with password
mysql -u root -p
```

Inside the MySQL prompt:

```sql
SHOW VARIABLES LIKE 'version';
SELECT VERSION();
SHOW DATABASES;
```

---

# 3. MariaDB Administration

## The mysql CLI

```bash
# Connect to local socket
mysql -u root -p

# Connect to remote host
mysql -h 192.168.1.100 -P 3306 -u admin -p

# Execute a single command
mysql -u root -p -e "SHOW DATABASES;"

# Source a SQL file
mysql -u root -p < /tmp/backup.sql
```

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

## User Operations

```sql
-- Show all users
SELECT User, Host, plugin FROM mysql.user;

-- Create a user
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'strong_password';
CREATE USER 'appuser'@'%' IDENTIFIED BY 'strong_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON company.* TO 'appuser'@'localhost';
GRANT SELECT, INSERT, UPDATE ON company.* TO 'readwrite'@'%';
GRANT SELECT ON company.* TO 'readonly'@'%';

-- Grant with option to grant to others
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;

-- Revoke privileges
REVOKE DELETE ON company.* FROM 'appuser'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- Drop a user
DROP USER 'appuser'@'localhost';

-- Change password
ALTER USER 'appuser'@'localhost' IDENTIFIED BY 'new_password';
```

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

## Authentication Plugins

MariaDB supports multiple authentication methods:

| Plugin | Description | Default in |
|--------|-------------|------------|
| `unix_socket` | Authenticate via OS user (no password) | MariaDB 10.4+ (root) |
| `mysql_native_password` | Legacy password hash | Older MySQL/MariaDB |
| `caching_sha2_password` | SHA-256 with caching | MySQL 8.0+ |
| `ed25519` | Public-key crypto | MariaDB 10.4+ |
| `pam` | PAM integration | Enterprise |

Check current root plugin:

```sql
SELECT User, Host, plugin FROM mysql.user WHERE User='root';
```

If root uses `unix_socket`, only `sudo mysql` works (no password needed).

## user@host Format

MariaDB identifies users by **username + host**:

```sql
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'pass';    -- only local socket connections
CREATE USER 'admin'@'%' IDENTIFIED BY 'pass';             -- any host
CREATE USER 'admin'@'192.168.1.%' IDENTIFIED BY 'pass';   -- subnet
CREATE USER 'admin'@'::1' IDENTIFIED BY 'pass';            -- IPv6 localhost
CREATE USER 'admin'@'db.example.com' IDENTIFIED BY 'pass'; -- specific hostname
```

**Important**: `'admin'@'localhost'` and `'admin'@'%'` are **different users**. You can have different passwords and privileges for each.

## Privilege Granularity

Privileges can be granted at these levels:

| Level | Syntax | Scope |
|-------|--------|-------|
| **Global** | `ON *.*` | All databases, all tables |
| **Database** | `ON db.*` | All tables in a database |
| **Table** | `ON db.table` | Specific table |
| **Column** | `ON db.table (col1, col2)` | Specific columns |
| **Procedure** | `ON PROCEDURE db.proc` | Stored procedure |

Common privilege types:

```sql
-- Read-only
GRANT SELECT ON db.* TO 'reader'@'%';

-- Read-write
GRANT SELECT, INSERT, UPDATE, DELETE ON db.* TO 'writer'@'%';

-- DDL operations
GRANT CREATE, ALTER, DROP, INDEX ON db.* TO 'developer'@'%';

-- Admin (but not GRANT)
GRANT ALL PRIVILEGES ON db.* TO 'owner'@'%';

-- Superuser
GRANT ALL PRIVILEGES ON *.* TO 'superadmin'@'localhost' WITH GRANT OPTION;
```

## View Effective Privileges

```sql
-- Show grants for current user
SHOW GRANTS;

-- Show grants for specific user
SHOW GRANTS FOR 'appuser'@'localhost';
```

## Best Practices

1. **No password in command line** — use `.my.cnf` for scripts:

```ini
# ~/.my.cnf
[client]
user = backupuser
password = SuperSecretPass
host = localhost
```

```bash
chmod 600 ~/.my.cnf
```

2. **Least privilege** — grant only what's needed
3. **No remote root** — `root` should only connect via socket
4. **Separate users per application** — easier to audit and revoke

---

# 5. MariaDB Backup

## mysqldump / mariadb-dump

Logical backup tool — exports SQL statements that recreate databases.

### Basic Usage

```bash
# Single database
mysqldump -u root -p company > company_backup.sql

# Specific tables
mysqldump -u root -p company products orders > products_orders.sql

# Multiple databases
mysqldump -u root -p --databases db1 db2 db3 > multi_db.sql

# All databases
mysqldump -u root -p --all-databases > full_backup.sql
```

### Various Options

```bash
# Include routines (stored procedures) and events
mysqldump -u root -p \
    --all-databases \
    --routines \
    --events \
    --triggers \
    > full_with_routines.sql

# Consistent InnoDB backup (no table locking)
mysqldump -u root -p \
    --single-transaction \
    --all-databases \
    > consistent_backup.sql

# With compression
mysqldump -u root -p company | gzip > company.sql.gz

# Exclude data (schema only)
mysqldump -u root -p --no-data company > schema_only.sql
```

### Restore

```bash
# Restore a single database
mysql -u root -p company < company_backup.sql

# Restore all databases
mysql -u root -p < full_backup.sql

# Restore from compressed file
gunzip < company.sql.gz | mysql -u root -p

# Create database then restore (if not included in dump)
mysql -u root -p -e "CREATE DATABASE newcompany"
mysql -u root -p newcompany < company_backup.sql
```

### Real-World Backup Script

```bash
#!/bin/bash
# /usr/local/bin/mariadb_backup.sh

BACKUP_DIR="/var/backups/mariadb"
DB_USER="backupuser"
DB_PASS="$(cat /etc/mariadb_backup_pass)"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR/$DATE"

mysqldump \
    --user="$DB_USER" \
    --password="$DB_PASS" \
    --all-databases \
    --single-transaction \
    --routines \
    --events \
    --triggers \
    | gzip > "$BACKUP_DIR/$DATE/full_backup.sql.gz"

# Check exit code
if [ $? -eq 0 ]; then
    echo "$(date): Backup succeeded" >> "$BACKUP_DIR/backup.log"
else
    echo "$(date): Backup FAILED" >> "$BACKUP_DIR/backup.log"
    exit 1
fi

# Cleanup old backups
find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

echo "Backup complete: $BACKUP_DIR/$DATE"
```

## Binary Log Backup (Point-in-Time Recovery)

Binary logs record every write operation. After restoring a full backup, replay binary logs to recover to a specific point.

### Enable Binary Logging

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
log_bin = /var/log/mysql/mariadb-bin
expire_logs_days = 7
max_binlog_size = 100M
```

### Tools

```bash
# List binary logs
mysql -u root -p -e "SHOW BINARY LOGS;"

# View binary log contents (as SQL)
mysqlbinlog /var/log/mysql/mariadb-bin.000001

# Replay binary logs (after restoring full backup)
mysqlbinlog /var/log/mysql/mariadb-bin.000001 /var/log/mysql/mariadb-bin.000002 \
    | mysql -u root -p

# Recover to a specific time
mysqlbinlog --stop-datetime="2026-06-23 14:30:00" /var/log/mysql/mariadb-bin.* \
    | mysql -u root -p

# Recover to a specific position
mysqlbinlog --stop-position=123456 /var/log/mysql/mariadb-bin.* \
    | mysql -u root -p
```

### Full Point-in-Time Recovery Procedure

```bash
# 1. Restore the full backup
mysql -u root -p < full_backup.sql

# 2. Replay binary logs since the backup
mysqlbinlog --start-datetime="2026-06-22 03:00:00" \
    --stop-datetime="2026-06-23 09:15:00" \
    /var/log/mysql/mariadb-bin.* \
    | mysql -u root -p

# 3. Verify data
mysql -u root -p -e "SELECT COUNT(*) FROM company.orders;"
```

## mariadb-dump (Modern Wrapper)

MariaDB 10.5+ provides `mariadb-dump` as a drop-in replacement:

```bash
mariadb-dump --all-databases > backup.sql
mariadb-dump --help
```

---

# 6. MariaDB Performance

## EXPLAIN — Query Execution Plan

```sql
EXPLAIN SELECT e.name, d.name
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE e.salary > 50000;
```

Output columns:

| Column | Meaning |
|--------|---------|
| `id` | SELECT identifier |
| `select_type` | SIMPLE, PRIMARY, SUBQUERY, etc. |
| `table` | Table name |
| `type` | Access method (ALL = full table scan, ref, eq_ref, const) |
| `possible_keys` | Indexes that could be used |
| `key` | Index actually used |
| `rows` | Estimated rows examined |
| `Extra` | Using index, Using where, Using filesort, etc. |

**Red flags**:
- `type: ALL` (full table scan) on large tables
- `rows` is very high
- `Extra: Using filesort` (sort without index)
- `Extra: Using temporary` (temp table for GROUP BY)

## Slow Query Log

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mariadb-slow.log
long_query_time = 2          # seconds — log queries slower than this
log_queries_not_using_indexes = 1
min_examined_row_limit = 100
```

```bash
# View slow queries
sudo tail -f /var/log/mysql/mariadb-slow.log

# Analyze slow query log with mysqldumpslow
mysqldumpslow /var/log/mysql/mariadb-slow.log
```

## InnoDB Buffer Pool

The **buffer pool** is InnoDB's cache for data and indexes. **This is the #1 performance tuning knob.**

```ini
[mysqld]
# Set to 70-80% of RAM on a dedicated DB server
innodb_buffer_pool_size = 4G

# If > 1GB, use multiple instances (reduces contention)
innodb_buffer_pool_instances = 4
```

Monitor buffer pool:

```sql
-- Hit rate (should be > 99%)
SHOW STATUS LIKE 'Innodb_buffer_pool_read%';

-- Calculate hit rate:
-- (Innodb_buffer_pool_read_requests - Innodb_buffer_pool_reads)
-- / Innodb_buffer_pool_read_requests * 100

-- Current size
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
```

## Query Cache (Deprecated)

MariaDB had a query cache, but it's **deprecated** and removed in MySQL 8.0+:

```ini
# MariaDB 10.1+ — not recommended
query_cache_type = 0
query_cache_size = 0
```

## Schema Optimization Tips

1. **Choose the right data types**:
   - `INT` vs `BIGINT` — use what you actually need
   - `VARCHAR(255)` wastes space — use realistic limits
   - `DATETIME` (5 bytes) vs `TIMESTAMP` (4 bytes)
   - `DECIMAL` for exact currency — never `FLOAT`

2. **Primary key matters**:
   - Use `INT AUTO_INCREMENT` or `UUID` (but UUIDs fragment B-trees)
   - InnoDB stores rows in primary key order (clustered index)

3. **Index selectively**:
   - Index columns used in `WHERE`, `JOIN`, `ORDER BY`
   - Don't over-index (slow down writes)
   - Composite indexes: order matters (most selective first)

```sql
-- Good index for: WHERE department_id = ? AND salary > ?
CREATE INDEX idx_dept_salary ON employees(department_id, salary);

-- This index can also serve: WHERE department_id = ?
-- But NOT: WHERE salary = ?
```

4. **Use `EXPLAIN` before deploying queries to production**

## Indexing Types in MariaDB/MySQL

| Index Type | Description | Use Case |
|-----------|-------------|----------|
| **B-tree** (default) | Balanced tree — good for equality and range | Most queries |
| **FULLTEXT** | Word-based search | `MATCH ... AGAINST` |
| **HASH** | Only in MEMORY engine | Equality lookups |
| **SPATIAL** | GIS data | Geometry columns |
| **UNIQUE** | Enforces uniqueness | Email, username |

---

# 7. PostgreSQL Installation

## Install PostgreSQL

```bash
# Update and install
sudo apt update
sudo apt install -y postgresql postgresql-client

# Check version
psql --version

# Check status
sudo systemctl status postgresql

# Enable on boot
sudo systemctl enable postgresql
```

## Initial Configuration

PostgreSQL creates a `postgres` system user and a `postgres` database role:

```bash
# Connect as postgres (via peer auth)
sudo -u postgres psql

# Set a password for the postgres role
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'newpassword';"
```

## Configuration Files

```bash
# Main config directory
ls /etc/postgresql/*/main/
#   postgresql.conf    — server settings
#   pg_hba.conf        — client authentication
#   pg_ident.conf      — user mapping

# Data directory (often a symlink)
ls /var/lib/postgresql/*/main/
```

### postgresql.conf

```ini
# /etc/postgresql/16/main/postgresql.conf

listen_addresses = 'localhost'    # '*' for all interfaces
port = 5432
max_connections = 100
shared_buffers = 256MB            # 25% of RAM for dedicated DB
effective_cache_size = 1GB
work_mem = 4MB                    # per-operation sort memory
maintenance_work_mem = 64MB       # for VACUUM, CREATE INDEX
wal_level = replica               # for replication
```

### pg_hba.conf

Controls **who can connect, how, and from where**:

```conf
# /etc/postgresql/16/main/pg_hba.conf

# TYPE  DATABASE    USER        ADDRESS          METHOD

# Local socket connections (peer = match OS user)
local   all         postgres                     peer
local   all         all                          peer

# TCP/IP connections (scram-sha-256 = password)
host    all         all         127.0.0.1/32     scram-sha-256
host    all         all         ::1/128          scram-sha-256

# Remote connections (require password)
host    all         all         192.168.1.0/24   scram-sha-256
```

## Authentication Methods

| Method | Description |
|--------|-------------|
| `trust` | No password — anyone can connect |
| `peer` | Match OS user with database user (local only) |
| `scram-sha-256` | Password-based (strongest) |
| `md5` | Legacy password hash |
| `password` | Cleartext (never use) |
| `ident` | Ident protocol (rare) |
| `cert` | SSL client certificate |
| `reject` | Deny connection |

---

# 8. PostgreSQL Administration

## The psql CLI

```bash
# Connect as postgres (peer auth — must be root or postgres OS user)
sudo -u postgres psql

# Connect to specific database
sudo -u postgres psql mydb

# Connect via TCP (password auth)
psql -h localhost -U myuser -d mydb -p 5432

# Execute a single command
psql -U postgres -c "SELECT version();"

# Execute a SQL file
psql -U postgres -f /tmp/backup.sql

# Connection info
\conninfo
```

## Meta-Commands (Backslash Commands)

```sql
-- List all databases
\l
\l+                         -- with sizes and descriptions

-- Connect to a database
\c mydb

-- List tables in current database
\dt
\dt+                        -- with additional info

-- List all schemas
\dn

-- Describe a table
\d employees
\d+ employees               -- with storage details

-- List views, sequences, indexes
\dv
\ds
\di

-- List all roles (users)
\du
\du+                        -- with member of

-- List functions
\df

-- Show query history
\s

-- Show current database and user
\conninfo

-- Execute shell command
\! ls -la

-- Show execution time of queries
\timing on

-- Help
\h CREATE TABLE
\?

-- Quit
\q
```

## Database Operations

```sql
-- Create database
CREATE DATABASE company;
CREATE DATABASE company OWNER 'appuser' ENCODING 'UTF8';

-- List databases (from psql)
\l

-- Connect to database
\c company

-- Drop database (cannot drop while connected to it)
DROP DATABASE company;
```

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

## Role (User) Operations

```sql
-- Create role (user)
CREATE ROLE appuser WITH LOGIN PASSWORD 'strong_password';

-- Create role with privileges
CREATE ROLE admin WITH LOGIN PASSWORD 'admin123' SUPERUSER;

-- List roles
\du

-- Alter role
ALTER ROLE appuser WITH PASSWORD 'new_password';
ALTER ROLE appuser WITH LOGIN;
ALTER ROLE appuser WITH NOLOGIN;        -- prevent login

-- Grant database access
GRANT ALL PRIVILEGES ON DATABASE company TO appuser;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO appuser;

-- Grant table privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO appuser;

-- Grant default privileges (for future tables)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;

-- Drop role
DROP ROLE appuser;

-- Show role attributes
\du+
```

## Groups and Membership

```sql
-- Create a group role (no LOGIN)
CREATE ROLE developers;

-- Grant privileges to the group
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO developers;

-- Add users to the group
GRANT developers TO alice;
GRANT developers TO bob;

-- Check members
\du+
```

---

# 9. PostgreSQL User Management — Deep Dive

## Role Attributes

PostgreSQL uses **roles** (not "users"). A role can have LOGIN or not:

| Attribute | Description | Example |
|-----------|-------------|---------|
| `LOGIN` | Can connect | `CREATE ROLE alice LOGIN;` |
| `SUPERUSER` | Bypasses all checks | `CREATE ROLE admin SUPERUSER;` |
| `CREATEDB` | Can create databases | `CREATE ROLE dev CREATEDB;` |
| `CREATEROLE` | Can create/modify roles | `CREATE ROLE manager CREATEROLE;` |
| `REPLICATION` | Can use replication protocol | `CREATE ROLE repl REPLICATION LOGIN;` |
| `BYPASSRLS` | Bypasses row-level security | `CREATE ROLE auditor BYPASSRLS;` |

## pg_hba.conf — Advanced Configuration

```conf
# TYPE    DATABASE    USER          ADDRESS          METHOD

# Trust local connections from postgres user
local    all         postgres                         peer

# Require SCRAM password for app users on local TCP
host     all         all           127.0.0.1/32      scram-sha-256

# Specific database for specific user from subnet
host     company     appuser       192.168.1.0/24    scram-sha-256

# Reject everyone else
host     all         all           0.0.0.0/0         reject

# SSL-only connections
hostssl  all         all           0.0.0.0/0         scram-sha-256

# Require SSL client certificate
hostssl  all         all           0.0.0.0/0         cert clientcert=1
```

## pg_ident.conf — User Mapping

Maps OS users to database roles:

```conf
# /etc/postgresql/16/main/pg_ident.conf

# MAPNAME       SYSTEM_USERNAME     PG_USERNAME
mymap           tim-ham             postgres
mymap           www-data            appuser
```

Then set `pg_hba.conf` to use `ident`:

```conf
host    all    all    192.168.1.0/24    ident map=mymap
```

## Password Encryption

PostgreSQL 10+ defaults to `scram-sha-256` (much stronger than `md5`):

```sql
-- Check password encryption
SHOW password_encryption;

-- Set encryption type
SET password_encryption = 'scram-sha-256';

-- Create user with specific encryption
CREATE ROLE appuser LOGIN PASSWORD 'mypass';
-- (uses current password_encryption setting)

-- Verify
SELECT rolname, rolpassword ~ 'SCRAM-SHA-256' AS is_scram
FROM pg_authid;
```

---

# 10. PostgreSQL Backup

## pg_dump — Single Database Backup

```bash
# Dump a single database (plain SQL)
pg_dump -U postgres company > company_backup.sql

# Custom format (compressed, flexible)
pg_dump -U postgres -Fc company > company_backup.dump

# Directory format (parallel capable)
pg_dump -U postgres -Fd company -j 4 -f /backup/company_dir/

# Exclude data (schema only)
pg_dump -U postgres --schema-only company > schema.sql

# Include only data
pg_dump -U postgres --data-only company > data.sql

# Specific table(s)
pg_dump -U postgres --table=employees --table=departments company > tables.sql

# Compression
pg_dump -U postgres -Z 9 company > company.sql.gz

# Exclude a table
pg_dump -U postgres --exclude-table=logs company > company.sql
```

## pg_dumpall — All Databases and Globals

```bash
# Dump all databases + roles + tablespaces
pg_dumpall -U postgres > all_databases.sql

# Roles only (for migrations)
pg_dumpall -U postgres --roles-only > roles.sql

# Schema only across all databases
pg_dumpall -U postgres --schema-only > all_schema.sql
```

## pg_restore — Restore Custom/Directory Format

```bash
# Restore custom format dump into a database
pg_restore -U postgres -d company company_backup.dump

# Create database first
createdb -U postgres newcompany
pg_restore -U postgres -d newcompany company_backup.dump

# Parallel restore (custom format only)
pg_restore -U postgres -d company -j 4 company_backup.dump

# List contents of a dump file
pg_restore -l company_backup.dump

# Restore specific table
pg_restore -U postgres -d company --table=employees company_backup.dump

# Clean (drop) objects before restoring
pg_restore -U postgres -d company --clean company_backup.dump
```

## Restore Plain SQL

```bash
# Restore a plain SQL dump
psql -U postgres -f company_backup.sql

# To a specific database
psql -U postgres -d company < company_backup.sql
```

## WAL Archiving (Continuous Archiving)

PostgreSQL's **Write-Ahead Log** (WAL) enables point-in-time recovery.

### Enable WAL Archiving

```ini
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/16/archive/%f'
archive_timeout = 60    # force a WAL switch at least every 60 seconds
```

### Create the Archive Directory

```bash
sudo mkdir -p /var/lib/postgresql/16/archive
sudo chown postgres:postgres /var/lib/postgresql/16/archive
sudo systemctl restart postgresql
```

### Take a Base Backup

```bash
# As postgres user
sudo -u postgres psql -c "SELECT pg_start_backup('base_backup_20260623');"

# Copy data directory
sudo cp -a /var/lib/postgresql/16/main /var/lib/postgresql/16/base_backup

# Stop the backup
sudo -u postgres psql -c "SELECT pg_stop_backup();"
```

### Point-in-Time Recovery

```bash
# 1. Stop PostgreSQL
sudo systemctl stop postgresql

# 2. Restore base backup
sudo rm -rf /var/lib/postgresql/16/main
sudo cp -a /var/lib/postgresql/16/base_backup /var/lib/postgresql/16/main

# 3. Create recovery signal file
sudo touch /var/lib/postgresql/16/main/recovery.signal

# 4. Create recovery.conf
# /var/lib/postgresql/16/main/postgresql.auto.conf
# restore_command = 'cp /var/lib/postgresql/16/archive/%f %p'
# recovery_target_time = '2026-06-23 14:30:00'

# 5. Start PostgreSQL (it will replay WAL)
sudo systemctl start postgresql

# 6. Check recovery status
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```

## pgBackRest (Modern Backup Tool)

```bash
# Install
sudo apt install -y pgbackrest

# Configure
# /etc/pgbackrest/pgbackrest.conf
# [mydb]
# pg1-path=/var/lib/postgresql/16/main
# repo1-path=/var/backups/pgbackrest
# repo1-type=posix

# Create a backup
sudo -u postgres pgbackrest --stanza=mydb --type=full backup

# List backups
sudo -u postgres pgbackrest --stanza=mydb info

# Restore
sudo systemctl stop postgresql
sudo -u postgres pgbackrest --stanza=mydb --delta restore
sudo systemctl start postgresql
```

---

# 11. PostgreSQL Performance

## EXPLAIN ANALYZE

PostgreSQL's `EXPLAIN ANALYZE` actually **executes** the query:

```sql
EXPLAIN ANALYZE
SELECT e.name, d.name
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE e.salary > 50000;
```

Output walkthrough:

```
Hash Join  (cost=12.34..45.67 rows=100 width=64)
  (actual time=0.123..0.456 rows=95 loops=1)
  Hash Cond: (e.department_id = d.id)
  ->  Seq Scan on employees e  (cost=0.00..25.00 rows=500 width=36)
        (actual time=0.010..0.100 rows=500 loops=1)
        Filter: (salary > 50000)
        Rows Removed by Filter: 405
  ->  Hash  (cost=10.00..10.00 rows=10 width=32)
        (actual time=0.020..0.020 rows=10 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        ->  Seq Scan on departments d  (cost=0.00..10.00 rows=10 width=32)
              (actual time=0.005..0.010 rows=10 loops=1)
Planning Time: 0.050 ms
Execution Time: 0.500 ms
```

**Red flags**:
- `Seq Scan` on large tables (missing index)
- `actual time` much higher than `cost` (bad estimates)
- `Rows Removed by Filter` is very high
- `Sort` without index
- `Execution Time` is too high for the query

## pg_stat_statements — Query Statistics

```sql
-- Enable in postgresql.conf:
-- shared_preload_libraries = 'pg_stat_statements'
-- Then restart and CREATE EXTENSION

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top queries by total time
SELECT queryid,
       ROUND(total_exec_time::numeric, 2) AS total_ms,
       calls,
       ROUND(mean_exec_time::numeric, 2) AS avg_ms,
       ROUND(rows / calls::numeric, 0) AS avg_rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Top queries by average time
SELECT queryid,
       ROUND(mean_exec_time::numeric, 2) AS avg_ms,
       calls,
       ROUND(total_exec_time::numeric, 2) AS total_ms,
       SUBSTRING(query, 1, 60) AS query_preview
FROM pg_stat_statements
WHERE calls > 10
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Reset statistics
SELECT pg_stat_statements_reset();
```

## Key Configuration Parameters

```ini
# shared_buffers — 25% of RAM (not higher!)
shared_buffers = 2GB

# effective_cache_size — OS cache estimate (50-75% of RAM)
effective_cache_size = 6GB

# work_mem — per-sort, per-join, per-hash memory
work_mem = 8MB

# maintenance_work_mem — for VACUUM, CREATE INDEX, ADD FOREIGN KEY
maintenance_work_mem = 256MB

# random_page_cost — how expensive random I/O is (SSD = 1.1, HDD = 4.0)
random_page_cost = 1.1

# max_parallel_workers_per_gather — parallel query workers
max_parallel_workers_per_gather = 4
```

## Autovacuum

PostgreSQL uses **MVCC** (Multi-Version Concurrency Control). Dead rows accumulate and must be cleaned up by **VACUUM**. **Autovacuum** runs automatically.

```ini
# Autovacuum settings
autovacuum = on
autovacuum_naptime = 1min
autovacuum_vacuum_threshold = 50
autovacuum_vacuum_scale_factor = 0.2     # 20% of table dead tuples
autovacuum_analyze_threshold = 50
autovacuum_analyze_scale_factor = 0.1    # 10% changed
```

Monitor autovacuum:

```sql
-- Check when tables were last vacuumed
SELECT relname,
       last_vacuum,
       last_autovacuum,
       last_analyze,
       n_dead_tup
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Check autovacuum workers running
SELECT * FROM pg_stat_progress_vacuum;
```

## Index Types in PostgreSQL

| Index Type | Description | Use Case |
|-----------|-------------|----------|
| **B-tree** (default) | Balanced tree — equality and range | Most general purpose |
| **Hash** | Equality only | Simple lookups |
| **GiST** | Generalized Search Tree | Full-text, geometry, ranges |
| **GIN** | Generalized Inverted Index | Arrays, JSONB, full-text |
| **BRIN** | Block Range Index | Huge tables with natural ordering (logs, time-series) |
| **SP-GiST** | Space-partitioned GiST | GIS, network addresses |

```sql
-- B-tree (default)
CREATE INDEX idx_emp_salary ON employees(salary);

-- Hash (equality only)
CREATE INDEX idx_emp_email ON employees USING HASH (email);

-- BRIN — great for append-only tables (logs)
CREATE INDEX idx_log_created ON logs USING BRIN (created_at);

-- GIN — for JSONB queries
CREATE INDEX idx_product_attrs ON products USING GIN (attributes);

-- Partial index — only index relevant rows
CREATE INDEX idx_active_users ON users(email) WHERE active = true;

-- Covering index — includes extra columns (no need to visit table)
CREATE INDEX idx_emp_dept_salary ON employees(department_id, salary);
```

---

# 12. Replication

## MariaDB Replication

### Binary Log and GTID

MariaDB's binary log records all write operations. Replication works by the replica reading the binary log from the primary.

**GTID** (Global Transaction ID) makes replication robust — each transaction has a unique ID.

### Enable Binary Logging (Primary)

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf (primary)
[mysqld]
server_id = 1
log_bin = /var/log/mysql/mariadb-bin
log_bin_index = /var/log/mysql/mariadb-bin.index
binlog_format = ROW
expire_logs_days = 7
gtid_strict_mode = 1
```

### Set Up a Replica

```bash
# 1. On the primary, create a replication user
mysql -u root -p -e "
CREATE USER 'repl'@'192.168.1.%' IDENTIFIED BY 'repl_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.1.%';
FLUSH PRIVILEGES;
"

# 2. Dump the primary
mysqldump -u root -p --all-databases --master-data=2 > /tmp/primary_dump.sql

# 3. Copy the dump to the replica
scp /tmp/primary_dump.sql replica:/tmp/

# 4. Configure replica's my.cnf
# /etc/mysql/mariadb.conf.d/50-server.cnf (replica)
[mysqld]
server_id = 2
log_bin = /var/log/mysql/mariadb-bin
relay_log = /var/log/mysql/mariadb-relay-bin
read_only = 1

# 5. Restart replica
sudo systemctl restart mariadb

# 6. Load the dump on the replica
mysql -u root -p < /tmp/primary_dump.sql

# 7. Start replication
mysql -u root -p -e "
CHANGE MASTER TO
  MASTER_HOST='192.168.1.10',
  MASTER_USER='repl',
  MASTER_PASSWORD='repl_password',
  MASTER_PORT=3306,
  MASTER_USE_GTID=current_pos;
START SLAVE;
"

# 8. Check replication status
mysql -u root -p -e "SHOW SLAVE STATUS\G"
```

### Monitor Replication

```sql
-- On the replica
SHOW SLAVE STATUS\G

-- Key fields to check:
-- Slave_IO_Running: Yes
-- Slave_SQL_Running: Yes
-- Seconds_Behind_Master: 0 (or low)
-- Last_IO_Error: (empty)
-- Last_SQL_Error: (empty)
```

### Troubleshooting Replication

```sql
-- Stop and restart
STOP SLAVE;
START SLAVE;

-- Skip one error (dangerous — only for known safe errors)
STOP SLAVE;
SET GLOBAL sql_slave_skip_counter = 1;
START SLAVE;

-- Re-sync from GTID position
STOP SLAVE;
RESET SLAVE;
CHANGE MASTER TO MASTER_USE_GTID=current_pos;
START SLAVE;
```

## PostgreSQL Streaming Replication

### Primary Configuration

```ini
# postgresql.conf (primary)
listen_addresses = '*'
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1024    # MB (or use replication slot)
```

```conf
# pg_hba.conf (primary)
# Allow replication connections
host    replication     repl    192.168.1.0/24    scram-sha-256
```

### Replica Setup

```bash
# 1. Create replication role on primary
sudo -u postgres psql -c "
CREATE ROLE repl WITH REPLICATION LOGIN PASSWORD 'repl_password';
"

# 2. Take a base backup (as postgres)
sudo -u postgres pg_basebackup \
    -h 192.168.1.10 \
    -D /var/lib/postgresql/16/main \
    -U repl \
    -P \
    -v \
    --wal-method=stream

# 3. Create standby signal
sudo touch /var/lib/postgresql/16/main/standby.signal

# 4. Configure primary connection
# /var/lib/postgresql/16/main/postgresql.auto.conf
# primary_conninfo = 'host=192.168.1.10 port=5432 user=repl password=repl_password'
# primary_slot_name = 'replica1'

# 5. On primary, create replication slot
sudo -u postgres psql -c "
SELECT pg_create_physical_replication_slot('replica1');
"

# 6. Start the replica
sudo systemctl start postgresql
```

### Monitor Streaming Replication

```sql
-- On primary
SELECT client_addr, state, sync_state, write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

-- On replica
SELECT pg_is_in_recovery();
SELECT pg_last_wal_receive_lsn();
SELECT pg_last_wal_replay_lsn();
SELECT pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()) AS lag_bytes;
```

### Synchronous Replication

```ini
# postgresql.conf (primary)
synchronous_standby_names = 'FIRST 1 (replica1)'
```

With synchronous replication, the primary waits for at least one replica to confirm writes. This guarantees **zero data loss** but increases latency.

### Logical Replication (PostgreSQL 10+)

Logical replication replicates individual tables (not the entire database):

```sql
-- On publisher
CREATE PUBLICATION mypub FOR TABLE employees, departments;

-- On subscriber
CREATE SUBSCRIPTION mysub CONNECTION 'host=192.168.1.10 dbname=company user=repl password=repl_password'
PUBLICATION mypub;
```

---

# 13. Database Monitoring

## MariaDB Monitoring

### SHOW PROCESSLIST

```sql
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;

-- Kill a stuck query
KILL 1234;
KILL CONNECTION 1234;
KILL QUERY 1234;    -- just the query, keep connection
```

### Monitor Connections

```sql
-- Current connections
SHOW STATUS LIKE 'Threads_connected';
SHOW VARIABLES LIKE 'max_connections';

-- Connection usage percentage
SELECT (SELECT VARIABLE_VALUE FROM information_schema.GLOBAL_STATUS
        WHERE VARIABLE_NAME = 'Threads_connected') /
       (SELECT VARIABLE_VALUE FROM information_schema.GLOBAL_VARIABLES
        WHERE VARIABLE_NAME = 'max_connections') * 100 AS connection_pct;
```

### Database Size

```sql
-- Size of all databases
SELECT table_schema AS database_name,
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.TABLES
GROUP BY table_schema;

-- Size of a specific table
SELECT table_name,
       ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'company' AND table_name = 'employees';
```

### Slow Query Log Monitoring

```bash
# Watch slow queries in real time
sudo tail -f /var/log/mysql/mariadb-slow.log

# Count slow queries per minute
sudo grep "$(date +%H:%M)" /var/log/mysql/mariadb-slow.log | wc -l

# Analyze with Percona Toolkit
sudo apt install percona-toolkit
pt-query-digest /var/log/mysql/mariadb-slow.log
```

## PostgreSQL Monitoring

### pg_stat_activity

```sql
-- All active connections
SELECT pid, usename, application_name, client_addr, state, query_start, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - pg_stat_activity.query_start > interval '5 minutes'
ORDER BY duration DESC;

-- Cancel a query
SELECT pg_cancel_backend(12345);

-- Terminate a connection
SELECT pg_terminate_backend(12345);
```

### Connection Monitoring

```sql
-- Connection count
SELECT count(*) FROM pg_stat_activity;

-- Connection limit
SHOW max_connections;

-- Connections by database
SELECT datname, count(*) AS connections
FROM pg_stat_activity
GROUP BY datname
ORDER BY connections DESC;

-- Connections by user
SELECT usename, count(*) AS connections
FROM pg_stat_activity
GROUP BY usename
ORDER BY connections DESC;
```

### Database and Table Sizes

```sql
-- Database sizes
SELECT datname,
       pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Table sizes
SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       pg_size_pretty(pg_relation_size(relid)) AS table_size,
       pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;
```

### Index Usage

```sql
-- Unused indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY tablename;

-- Index vs seq scan ratio
SELECT relname,
       seq_scan,
       idx_scan,
       CASE WHEN seq_scan + idx_scan > 0
            THEN round(100.0 * idx_scan / (seq_scan + idx_scan), 2)
            ELSE 0
       END AS idx_scan_pct
FROM pg_stat_user_tables
WHERE seq_scan + idx_scan > 0
ORDER BY seq_scan DESC;
```

## Monitoring Tools

```bash
# Percona Toolkit (MariaDB/MySQL)
pt-query-digest /var/log/mysql/mariadb-slow.log
pt-mysql-summary
pt-variable-advisor
pt-index-usage

# pgBadger (PostgreSQL)
# Install from source or package
pgbadger /var/log/postgresql/postgresql-16-main.log

# pg_stat_statements (built-in)
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
```

---

# 14. Troubleshooting

## Connection Refused

### MariaDB

```bash
# Check if MariaDB is running
sudo systemctl status mariadb

# Check bind address
sudo ss -tlnp | grep 3306

# Is it listening on all interfaces?
# If bind-address = 127.0.0.1, only local connections work

# Check firewall
sudo ufw status
sudo iptables -L -n | grep 3306

# Is the user allowed from this host?
mysql -u root -p -e "SELECT User, Host FROM mysql.user WHERE User='appuser';"

# Test connection manually
mysql -h 192.168.1.100 -u appuser -p -e "SELECT 1;"
```

### PostgreSQL

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check listening address
sudo ss -tlnp | grep 5432

# Check pg_hba.conf
sudo grep -v '^#' /etc/postgresql/16/main/pg_hba.conf | grep -v '^$'

# Test connection
psql -h localhost -U appuser -d company -c "SELECT 1;"
```

## max_connections Reached

### MariaDB

```sql
SHOW VARIABLES LIKE 'max_connections';
SHOW STATUS LIKE 'Threads_connected';

-- Increase temporarily (until restart)
SET GLOBAL max_connections = 500;

-- Permanent change in my.cnf:
-- [mysqld]
-- max_connections = 500
```

### PostgreSQL

```sql
SHOW max_connections;
SELECT count(*) FROM pg_stat_activity;

-- Needs restart (can't change at runtime)
-- ALTER SYSTEM max_connections = '500';
-- sudo systemctl restart postgresql
```

## Disk Full (WAL Growth)

### Problem

PostgreSQL can accumulate WAL files in `pg_wal/` if WAL archiving fails or replication lags.

```bash
# Check WAL directory size
sudo du -sh /var/lib/postgresql/16/main/pg_wal/

# Check if WAL archiving is stuck
sudo -u postgres psql -c "SELECT * FROM pg_stat_archiver;"
```

### Fix

```bash
# 1. Identify the problem (disk full, archive command failing)
# 2. Free up space
sudo journalctl --vacuum-time=1d

# 3. Remove old WAL files if archiving failed (CAUTION!)
# Only after ensuring they've been archived or aren't needed
# Check which WAL files can be removed
sudo -u postgres psql -c "SELECT pg_switch_wal();"
# Remove WAL up to the last checkpoint:
sudo -u postgres psql -c "SELECT pg_current_wal_lsn(), pg_last_checkpoint_lsn();"

# 4. Fix the archive command and restart
```

### MariaDB — Binary Log Growth

```bash
# Check binary log disk usage
sudo du -sh /var/log/mysql/

# Remove old binary logs
mysql -u root -p -e "PURGE BINARY LOGS BEFORE NOW() - INTERVAL 3 DAY;"
```

## Stale Replication

### MariaDB

```sql
SHOW SLAVE STATUS\G
-- Check: Slave_IO_Running, Slave_SQL_Running, Last_IO_Error, Last_SQL_Error

-- If IO thread is not running:
-- Network issue? Can the replica reach the primary?
-- Check with: ping, telnet, mysql -h primary -u repl -p

-- If SQL thread stopped (duplicate key, missing row):
STOP SLAVE;
SET GLOBAL sql_slave_skip_counter = 1;
START SLAVE;

-- Or re-sync:
STOP SLAVE;
RESET SLAVE;
CHANGE MASTER TO MASTER_USE_GTID=current_pos;
START SLAVE;
```

### PostgreSQL

```sql
-- Check replication status on primary
SELECT client_addr, state, write_lag, flush_lag, replay_lag
FROM pg_stat_replication
WHERE application_name = 'replica1';

-- On replica, check lag
SELECT pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()) AS lag_bytes;

-- If lag is growing:
-- Is the replica powerful enough? CPU, I/O?
-- Is network bandwidth saturated?
-- Try increasing:
--   max_wal_senders, max_worker_processes, wal_receiver_buffer_size
```

## Lock Waits and Deadlocks

### MariaDB

```sql
-- Show current locks
SHOW OPEN TABLES WHERE In_use > 0;
SHOW ENGINE INNODB STATUS\G

-- Find blocking transactions
SELECT * FROM information_schema.INNODB_LOCK_WAITS;
SELECT * FROM information_schema.INNODB_TRX\G

-- Kill blocking transaction
KILL <trx_mysql_thread_id>;
```

### PostgreSQL

```sql
-- Find blocked queries
SELECT blocked.pid AS blocked_pid,
       blocked.query AS blocked_query,
       blocking.pid AS blocking_pid,
       blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocked.pid != blocking.pid
WHERE blocked.wait_event_type = 'Lock';

-- Cancel blocking query
SELECT pg_cancel_backend(<blocking_pid>);

-- Or terminate
SELECT pg_terminate_backend(<blocking_pid>);

-- Deadlock log (check PostgreSQL logs)
sudo tail -f /var/log/postgresql/postgresql-16-main.log
-- Search for "deadlock detected"
```

---

# 15. Hands-On Practices

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

## Practice 3: mysqldump Backup and Restore

```bash
# 1. Create a full backup
mysqldump -u invapp -pinventory_pass \
    --single-transaction \
    --routines \
    inventory > /tmp/inventory_backup.sql

# 2. Drop the database
sudo mysql -e "DROP DATABASE inventory;"

# 3. Restore
sudo mysql -e "CREATE DATABASE inventory;"
mysql -u invapp -pinventory_pass inventory < /tmp/inventory_backup.sql

# 4. Verify data integrity
mysql -u invapp -pinventory_pass -e "SELECT COUNT(*) FROM inventory.items;"
```

## Practice 4: PostgreSQL Role and Database

```bash
# 1. Connect as postgres
sudo -u postgres psql << 'SQL'
CREATE ROLE invadmin WITH LOGIN PASSWORD 'securepass';
CREATE DATABASE inventory OWNER invadmin;
\c inventory
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    quantity INTEGER DEFAULT 0,
    price NUMERIC(10,2)
);
INSERT INTO items (name, quantity, price) VALUES
    ('Widget', 100, 9.99),
    ('Gadget', 50, 24.99);
GRANT ALL ON ALL TABLES IN SCHEMA public TO invadmin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO invadmin;
SQL

# 2. Connect as application user
psql -h localhost -U invadmin -d inventory -c "SELECT * FROM items;"
```

## Practice 5: pg_dump/pg_restore

```bash
# 1. Backup
pg_dump -U invadmin -h localhost -Fc inventory > /tmp/inventory.dump

# 2. Drop and recreate
sudo -u postgres psql -c "DROP DATABASE inventory;"
sudo -u postgres psql -c "CREATE DATABASE inventory OWNER invadmin;"

# 3. Restore
pg_restore -U invadmin -h localhost -d inventory /tmp/inventory.dump

# 4. Verify
psql -U invadmin -h localhost -d inventory -c "SELECT * FROM items;"
```

## Practice 6: EXPLAIN a Slow Query

```bash
# 1. Create a large dataset
sudo -u postgres psql -d inventory << 'SQL'
INSERT INTO items (name, quantity, price)
SELECT 'Item_' || generate_series(1, 100000),
       floor(random() * 1000),
       round((random() * 100)::numeric, 2);
SQL

# 2. Enable timing
sudo -u postgres psql -d inventory -c "\timing"

# 3. Run a slow query (no index on quantity)
sudo -u postgres psql -d inventory -c "
EXPLAIN ANALYZE SELECT * FROM items WHERE quantity > 500 ORDER BY price;
"

# 4. Add an index
sudo -u postgres psql -d inventory -c "
CREATE INDEX idx_items_quantity ON items(quantity);
"

# 5. Run the query again — compare the plan
sudo -u postgres psql -d inventory -c "
EXPLAIN ANALYZE SELECT * FROM items WHERE quantity > 500 ORDER BY price;
"
```

## Practice 7: Tune Buffer Sizes

```bash
# 1. Check current MariaDB buffer pool size
sudo mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# 2. Calculate 70% of system RAM
free -g

# 3. Update MariaDB config
echo -e "[mysqld]\ninnodb_buffer_pool_size = 1G" | \
    sudo tee /etc/mysql/mariadb.conf.d/99-tuning.cnf
sudo systemctl restart mariadb

# 4. Verify new setting
sudo mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# 5. Same for PostgreSQL
echo -e "shared_buffers = 512MB\neffective_cache_size = 2GB" | \
    sudo tee /etc/postgresql/16/main/conf.d/tuning.conf
sudo systemctl restart postgresql
sudo -u postgres psql -c "SHOW shared_buffers;"
sudo -u postgres psql -c "SHOW effective_cache_size;"
```

## Practice 8: Set Up PostgreSQL Streaming Replication

```bash
# On PRIMARY (192.168.1.10):
# 1. Configure
echo -e "wal_level = replica\nmax_wal_senders = 5\nwal_keep_size = 512" | \
    sudo tee -a /etc/postgresql/16/main/conf.d/replication.conf
sudo systemctl restart postgresql

# 2. Create replication user
sudo -u postgres psql -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'rep_pass';"

# On REPLICA (192.168.1.20):
# 3. Stop PostgreSQL
sudo systemctl stop postgresql

# 4. Take base backup
sudo -u postgres pg_basebackup -h 192.168.1.10 -U replicator \
    -D /var/lib/postgresql/16/main -P -v --wal-method=stream

# 5. Create standby signal
sudo touch /var/lib/postgresql/16/main/standby.signal

# 6. Configure connection
echo "primary_conninfo = 'host=192.168.1.10 port=5432 user=replicator password=rep_pass'" | \
    sudo tee /var/lib/postgresql/16/main/postgresql.auto.conf

# 7. Start
sudo systemctl start postgresql

# 8. Check status
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```

## Practice 9: Configure Slow Query Log

```bash
# MariaDB
echo -e "[mysqld]\nslow_query_log = 1\nslow_query_log_file = /var/log/mysql/slow.log\nlong_query_time = 1" | \
    sudo tee /etc/mysql/mariadb.conf.d/99-slow-log.conf
sudo systemctl restart mariadb

# Generate a slow query
sudo mysql -e "SELECT BENCHMARK(50000000, MD5('test'));"

# Check the slow log
sudo tail -5 /var/log/mysql/slow.log

# PostgreSQL
echo -e "log_min_duration_statement = 1000\nlog_statement = 'ddl'\nlog_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h'" | \
    sudo tee /etc/postgresql/16/main/conf.d/logging.conf
sudo systemctl restart postgresql

# Generate a slow query
sudo -u postgres psql -d inventory -c "SELECT pg_sleep(2);"

# Check the log
sudo tail /var/log/postgresql/postgresql-16-main.log
```

## Practice 10: Monitor Connections

```bash
# MariaDB — watch process list
watch -n 2 "sudo mysql -e 'SHOW PROCESSLIST;'"

# PostgreSQL — watch active queries
watch -n 2 "sudo -u postgres psql -c \"
  SELECT pid, usename, state, left(query, 50)
  FROM pg_stat_activity
  WHERE state != 'idle';
\""

# Simulate connections (in another terminal)
for i in $(seq 1 5); do
    mysql -u invapp -pinventory_pass -e "SELECT SLEEP(30);" &
    psql -h localhost -U invadmin -d inventory -c "SELECT pg_sleep(30);" &
done
```

## Practice 11: pt-query-digest (Percona Toolkit)

```bash
# Install Percona Toolkit
sudo apt install -y percona-toolkit

# Analyze MariaDB slow query log
sudo pt-query-digest /var/log/mysql/slow.log

# Analyze from live (capture 60 seconds)
sudo pt-query-digest --processlist h=localhost,u=root
```

## Practice 12: Troubleshoot a Stuck Query

```bash
# 1. Start a long transaction
mysql -u invapp -pinventory_pass -e "BEGIN; UPDATE inventory.items SET quantity = quantity - 1 WHERE id = 1; SELECT SLEEP(60); COMMIT;" &

# 2. In another terminal, find and kill it
sudo mysql -e "SHOW PROCESSLIST;"
sudo mysql -e "KILL <thread_id>;"

# Same for PostgreSQL
psql -h localhost -U invadmin -d inventory -c "BEGIN; UPDATE items SET quantity = quantity - 1 WHERE id = 1; SELECT pg_sleep(60); COMMIT;" &
sudo -u postgres psql -c "SELECT pid, query FROM pg_stat_activity WHERE state = 'active';"
sudo -u postgres psql -c "SELECT pg_cancel_backend(<pid>);"
```

## Practice 13: Database Size Monitoring

```bash
# MariaDB
sudo mysql << 'SQL'
SELECT table_schema AS db,
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.TABLES
GROUP BY table_schema
ORDER BY size_mb DESC;
SQL

# PostgreSQL
sudo -u postgres psql << 'SQL'
SELECT datname,
       pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;
SQL
```

## Practice 14: Point-in-Time Recovery

```bash
# 1. Enable binary logging on MariaDB
echo -e "[mysqld]\nlog_bin = /var/log/mysql/bin-log" | \
    sudo tee /etc/mysql/mariadb.conf.d/99-binlog.conf
sudo systemctl restart mariadb

# 2. Create a backup
mysqldump -u root -p --all-databases --single-transaction --master-data=2 > /tmp/full.sql

# 3. Make some changes
sudo mysql -e "CREATE DATABASE testpitr; USE testpitr; CREATE TABLE t (id INT); INSERT INTO t VALUES (1);"

# 4. Note the time
date '+%Y-%m-%d %H:%M:%S'

# 5. Make more changes
sudo mysql -e "INSERT INTO testpitr.t VALUES (2);"

# 6. Restore to before the second change
sudo mysql -u root -p < /tmp/full.sql
mysqlbinlog --stop-datetime="<time_from_step_4>" /var/log/mysql/bin-log.* | sudo mysql -u root -p

# 7. Verify
sudo mysql -e "SELECT * FROM testpitr.t;"  # Should only show id=1
```

## Practice 15: Real-World Integration — Complete Backup and Monitoring Script

```bash
#!/bin/bash
# /usr/local/bin/db_ops.sh — Complete database backup and monitoring
# Run daily from cron: 0 3 * * * root /usr/local/bin/db_ops.sh

set -euo pipefail

BACKUP_ROOT="/var/backups/databases"
MARIADB_USER="root"
PG_USER="postgres"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION=7
ALERT_EMAIL="admin@example.com"

# Create backup directories
mkdir -p "$BACKUP_ROOT/mariadb/$DATE"
mkdir -p "$BACKUP_ROOT/postgresql/$DATE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') — $1" | tee -a "$BACKUP_ROOT/backup.log"
}

alert() {
    local subject="$1"
    local message="$2"
    log "ALERT: $subject — $message"
    # mail -s "$subject" "$ALERT_EMAIL" <<< "$message"
}

# === MariaDB Backup ===
backup_mariadb() {
    log "Starting MariaDB backup..."

    if ! systemctl is-active --quiet mariadb; then
        alert "MariaDB Backup Failed" "MariaDB service is not running"
        return 1
    fi

    # Check connection count
    CONN=$(mysql -u root -e "SELECT COUNT(*) FROM information_schema.PROCESSLIST;" 2>/dev/null | tail -1)
    MAXCONN=$(mysql -u root -e "SHOW VARIABLES LIKE 'max_connections';" 2>/dev/null | awk '{print $2}')
    log "MariaDB connections: $CONN / $MAXCONN"

    if [ "$CONN" -gt $((MAXCONN * 80 / 100)) ]; then
        alert "MariaDB Connection Alert" "Connection count at ${CONN} (${MAXCONN} max)"
    fi

    # Perform dump
    if mysqldump -u root \
        --all-databases \
        --single-transaction \
        --routines \
        --events \
        --triggers \
        | gzip > "$BACKUP_ROOT/mariadb/$DATE/full.sql.gz"; then
        log "MariaDB backup completed: $(du -sh "$BACKUP_ROOT/mariadb/$DATE/full.sql.gz" | cut -f1)"
    else
        alert "MariaDB Backup Failed" "mysqldump exited with code $?"
        return 1
    fi

    # Cleanup old backups
    find "$BACKUP_ROOT/mariadb" -mindepth 1 -maxdepth 1 -type d -mtime +$RETENTION \
        -exec rm -rf {} \; -exec log "Removed old MariaDB backup: {}" \;
}

# === PostgreSQL Backup ===
backup_postgresql() {
    log "Starting PostgreSQL backup..."

    if ! systemctl is-active --quiet postgresql; then
        alert "PostgreSQL Backup Failed" "PostgreSQL service is not running"
        return 1
    fi

    # Check connections
    CONN=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity;" | tr -d ' ')
    MAXCONN=$(sudo -u postgres psql -t -c "SHOW max_connections;" | tr -d ' ')
    log "PostgreSQL connections: $CONN / $MAXCONN"

    if [ "$CONN" -gt $((MAXCONN * 80 / 100)) ]; then
        alert "PostgreSQL Connection Alert" "Connection count at ${CONN} (${MAXCONN} max)"
    fi

    # Dump globals (roles + tablespaces)
    sudo -u postgres pg_dumpall --globals-only \
        | gzip > "$BACKUP_ROOT/postgresql/$DATE/globals.sql.gz"

    # Dump all databases (custom format, parallel)
    sudo -u postgres pg_dumpall \
        | gzip > "$BACKUP_ROOT/postgresql/$DATE/all_databases.sql.gz"

    if [ $? -eq 0 ]; then
        log "PostgreSQL backup completed: $(du -sh "$BACKUP_ROOT/postgresql/$DATE/" | cut -f1)"
    else
        alert "PostgreSQL Backup Failed" "pg_dumpall exited with code $?"
        return 1
    fi

    # Cleanup old backups
    find "$BACKUP_ROOT/postgresql" -mindepth 1 -maxdepth 1 -type d -mtime +$RETENTION \
        -exec rm -rf {} \; -exec log "Removed old PostgreSQL backup: {}" \;
}

# === Monitoring ===
monitor_databases() {
    log "Running database monitoring checks..."

    # MariaDB — check for long-running queries
    LONG_QUERIES=$(mysql -u root -e "
        SELECT id, TIME_TO_SEC(TIME) AS seconds, INFO
        FROM information_schema.PROCESSLIST
        WHERE TIME > 300 AND COMMAND != 'Sleep'
        ORDER BY TIME DESC;
    " 2>/dev/null)

    if [ -n "$LONG_QUERIES" ] && [ "$(echo "$LONG_QUERIES" | wc -l)" -gt 1 ]; then
        alert "MariaDB Long Queries" "Queries running >5 minutes:\n$LONG_QUERIES"
    fi

    # PostgreSQL — check for long-running queries
    PG_LONG=$(sudo -u postgres psql -t -c "
        SELECT pid, now() - query_start AS duration, left(query, 80)
        FROM pg_stat_activity
        WHERE state = 'active'
          AND now() - query_start > interval '5 minutes'
        ORDER BY duration DESC;
    " 2>/dev/null)

    if [ -n "$PG_LONG" ]; then
        alert "PostgreSQL Long Queries" "Queries running >5 minutes:\n$PG_LONG"
    fi

    # Check disk space for backup directory
    DISK_USAGE=$(df -h "$BACKUP_ROOT" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 85 ]; then
        alert "Backup Disk Space" "Backup directory is ${DISK_USAGE}% full"
    fi

    log "Monitoring checks completed"
}

# === Main ===
log "========== Database Backup & Monitoring Run =========="

backup_mariadb
backup_postgresql
monitor_databases

log "========== Run Completed =========="
echo ""
echo "Backups stored in: $BACKUP_ROOT"
echo "  MariaDB: $BACKUP_ROOT/mariadb/$DATE/"
echo "  PostgreSQL: $BACKUP_ROOT/postgresql/$DATE/"
echo "Log: $BACKUP_ROOT/backup.log"
```

```bash
# Make it executable and set up cron
sudo chmod +x /usr/local/bin/db_ops.sh

# Add to cron (runs daily at 3 AM)
echo "0 3 * * * root /usr/local/bin/db_ops.sh" | sudo tee /etc/cron.d/db_backup
```

**Test the script**:
```bash
sudo /usr/local/bin/db_ops.sh
sudo cat /var/backups/databases/backup.log
```

---

# 🔬 Deep Understanding

## How Storage Engines Work (InnoDB)

### Page Structure

InnoDB stores data in **16 KB pages** (the default `innodb_page_size`).

```
┌─────────────────────────────────────┐
│ Page Header (38 bytes)              │
│   - Checksum                        │
│   - Page number                     │
│   - Page type (index, undo, etc.)   │
│   - LSN (Log Sequence Number)       │
├─────────────────────────────────────┤
│ Infimum / Supremum records          │
│   (boundary markers)                │
├─────────────────────────────────────┤
│ User Records (row data)             │
│   Row 1: header + fields            │
│   Row 2: header + fields            │
│   ...                               │
│   Linked in ascending key order     │
├─────────────────────────────────────┤
│ Free Space                          │
├─────────────────────────────────────┤
│ Page Directory (slot array)         │
│   (points to record offsets)        │
├─────────────────────────────────────┤
│ Page Trailer (8 bytes)              │
│   - Checksum copy                   │
│   - LSN copy                        │
└─────────────────────────────────────┘
```

### B-Tree Index

InnoDB uses a **B+ Tree** (clustered index) where:

- **Root node** points to internal nodes
- **Internal nodes** contain key ranges and pointers
- **Leaf nodes** contain the actual row data (for the primary key)

```
                    [50]
                   /    \
               [25]      [75]
              /    \    /    \
            [1-24] [25-49] [50-74] [75-...]
            (data)  (data)  (data)  (data)
```

**Secondary indexes** (non-clustered) store the primary key value as a pointer to the row.

- Index lookup: O(log n) — extremely fast
- Full table scan: O(n) — slow on large tables

### Buffer Pool

The **buffer pool** caches pages in memory:

- **LRU list** — recently accessed pages stay in memory
- **Flush list** — dirty pages (modified but not written to disk)
- **Free list** — empty pages ready for use

```sql
-- Check buffer pool status
SHOW ENGINE INNODB STATUS\G
-- Look for "BUFFER POOL AND MEMORY" section
```

### Redo Log

The **redo log** records every change before it's written to the data files (WAL — Write-Ahead Log):

1. Transaction modifies a page → change written to **redo log buffer**
2. `COMMIT` → redo log buffer flushed to **redo log file** on disk
3. Eventually, the modified page is written to the **data file** (checkpoint)

This guarantees **durability** even if the server crashes between step 2 and 3.

```ini
innodb_log_file_size = 256M     # total redo log size
innodb_log_buffer_size = 16M    # in-memory redo buffer
innodb_flush_log_at_trx_commit = 1  # 1=fsync every commit (safest)
```

### Undo Log and MVCC

**MVCC** (Multi-Version Concurrency Control) allows readers to see a consistent snapshot without blocking writers.

- Each transaction sees a **snapshot** of the database at the start of the transaction
- When a row is updated, the old version is stored in the **undo log**
- Readers see the old version until the writer commits
- After commit, the undo log is purged (by the purge thread)

```sql
-- Check undo log status
SHOW STATUS LIKE 'Innodb_undo%';
```

## PostgreSQL Process Architecture

Unlike MariaDB (thread-based), PostgreSQL uses a **process-per-connection** model.

```
┌──────────────────────────────────────────────────────────┐
│                   postmaster (PID 1)                      │
│   - Listens on TCP port 5432                              │
│   - Forks new backend for each connection                 │
│   - Restarts crashed backends                             │
│   - Manages shared memory                                 │
└──────────────────────────────────────────────────────────┘
         │                │              │
         ▼                ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Backend (PID)│  │  Backend (PID)│  │  Backend (PID)│
│  (connection) │  │  (connection) │  │  (connection) │
└──────────────┘  └──────────────┘  └──────────────┘

┌──────────────────────────────────────────────────────────┐
│                    Background Processes                    │
│                                                            │
│  WAL Writer    │  Checkpointer  │  Autovacuum Launcher     │
│  (flushes WAL) │  (checkpoints) │  (starts workers)        │
│                                                            │
│  BG Writer     │  Archiver      │  Statistics Collector    │
│  (dirty pages) │  (WAL archive) │  (pg_stat_*)             │
│                                                            │
│  WAL Sender(s) │  WAL Receiver  │  Logical Replication     │
│  (replication) │  (standby)     │  (pgoutput plugin)        │
└──────────────────────────────────────────────────────────┘
```

### Key Processes

| Process | Description |
|---------|-------------|
| **postmaster** | Main daemon — listens, forks, coordinates |
| **Backend** | One per client connection — runs queries |
| **WAL Writer** | Flushes WAL buffer to disk periodically |
| **Checkpointer** | Writes dirty shared_buffers to disk, creates checkpoints |
| **Autovacuum Launcher** | Schedules autovacuum workers |
| **Autovacuum Worker** | Cleans up dead rows |
| **BG Writer** | Writes dirty shared_buffers in background (reduces checkpoint I/O) |
| **WAL Sender** | Sends WAL to replicas (streaming replication) |
| **WAL Receiver** | Receives WAL on replica |
| **Archiver** | Copies WAL segments to archive location |

### How WAL Guarantees Durability

PostgreSQL's WAL (Write-Ahead Log) ensures that **no committed transaction is ever lost**:

```
Transaction flow:
1. BEGIN
2. UPDATE table SET x = 5 WHERE id = 1
3. The change is written to WAL buffer (in memory)
4. COMMIT
   a. WAL buffer is flushed to WAL file on disk (fsync)
   b. Transaction is marked committed
5. Later: Checkpointer writes dirty pages from shared_buffers to data files
6. Even later: WAL segments can be recycled/archived

Crash recovery (after crash at step 4-5):
- PostgreSQL reads the last checkpoint position
- Replays WAL from the checkpoint forward (REDO)
- This reconstructs all committed changes that hadn't been written to data files
```

```ini
# WAL settings
wal_level = replica           # how much info to write in WAL
wal_buffers = 16MB            # in-memory WAL buffer
wal_writer_delay = 200ms      # how often WAL writer flushes
wal_sync_method = fdatasync   # sync method for WAL
full_page_writes = on         # protects against partial page writes
minimum_wal_size = 80MB
max_wal_size = 1GB
checkpoint_timeout = 5min     # time between checkpoints
checkpoint_completion_target = 0.9  # spread checkpoint I/O
```

### Shared Buffers and Memory Architecture

```
┌───────────────────────────────────────────────────────────┐
│                    Shared Memory                            │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐│
│  │ shared_buf- │  │ WAL Buffer  │  │ Lock Manager        ││
│  │ fers (data  │  │ (wal_buff-  │  │ (lightweight locks) ││
│  │ + indexes)  │  │ ers)        │  │                     ││
│  └─────────────┘  └─────────────┘  └─────────────────────┘│
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐│
│  │ Proc Array  │  │ Subtransac- │  │ Clog (commit log)   ││
│  │ (processes) │  │ tion Slots  │  │ (transaction status) ││
│  └─────────────┘  └─────────────┘  └─────────────────────┘│
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐│
│  │ Notify      │  │ Serialize   │  │ Shared Plan Cache   ││
│  │ (LISTEN/    │  │ (sequence   │  │ (prepared plans)    ││
│  │ NOTIFY)     │  │ cache)      │  │                     ││
│  └─────────────┘  └─────────────┘  └─────────────────────┘│
└───────────────────────────────────────────────────────────┘
```

**Each backend process** also has its own private memory:

- `work_mem` — for sorting, hash tables (per operation, not per connection)
- `maintenance_work_mem` — for VACUUM, CREATE INDEX

---

# 📋 Command Reference

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

---

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

---

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

---

# 📚 Footer

```
Previous → Part 39: Web Servers
Next → Part 41: LDAP and Centralized Authentication
```

---

*"A database is only as reliable as its backup strategy, and only as fast as its slowest query."*

[← Previous](part39.md) | [Next →](part41.md)
