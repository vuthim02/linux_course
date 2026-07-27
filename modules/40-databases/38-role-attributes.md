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



---

[← Previous](37-groups-and-membership.md) | [↑ Index](index.md) | [Next →](39-pghbaconf-advanced-configuration.md)
