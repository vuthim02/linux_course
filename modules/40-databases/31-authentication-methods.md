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

### Example pg_hba.conf Rules

```conf
# Local socket: trust for postgres user only
local   all   postgres                 peer

# Local socket: require password for everyone else
local   all   all                      scram-sha-256

# TCP: require password from application subnet
host    all   all   192.168.1.0/24      scram-sha-256

# Remote: reject everything else
host    all   all   0.0.0.0/0          reject
```

### Migration Path: md5 → scram-sha-256

```sql
-- In postgresql.conf:
-- password_encryption = scram-sha-256

-- Re-encrypt all passwords:
ALTER USER appuser PASSWORD 'newpassword';
```

### Key Takeaway
Always use `scram-sha-256` for new deployments. Only use `md5` for compatibility with older clients. Never use `trust` in production.


# 8. PostgreSQL Administration


[← Previous](30-configuration-files.md) | [↑ Index](index.md) | [Next →](32-the-psql-cli.md)
