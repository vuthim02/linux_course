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

### Combining Attributes

```sql
-- A developer role that can create databases and log in
CREATE ROLE devteam LOGIN CREATEDB PASSWORD 'devpass';

-- A read-only analyst (no LOGIN by default — use GRANT to grant connection)
CREATE ROLE analyst PASSWORD 'readpass';
GRANT CONNECT ON DATABASE company TO analyst;
GRANT USAGE ON SCHEMA public TO analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst;
```

### Viewing Role Properties

```sql
SELECT rolname, rolsuper, rolcreatedb, rolcanlogin, rolreplication
FROM pg_roles WHERE rolname = 'devteam';
```

### Key Takeaway
Use roles as a group mechanism: create a role with the right privileges, then `GRANT` that role to individual users. This is cleaner than granting privileges to each user separately.


[← Previous](37-groups-and-membership.md) | [↑ Index](index.md) | [Next →](39-pghbaconf-advanced-configuration.md)
