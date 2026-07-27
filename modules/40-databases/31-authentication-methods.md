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



---

[← Previous](30-configuration-files.md) | [↑ Index](index.md) | [Next →](32-the-psql-cli.md)
