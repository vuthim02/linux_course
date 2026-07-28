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

### When to Use Ident Mapping

- **Development environments** where OS users map directly to database roles
- **Cron jobs** running as specific system users
- **Web applications** running as `www-data` or a dedicated service user

### Verifying the Mapping

```bash
# Test ident resolution
select ident_lookup('www-data', 'mymap');

# Check if a connection would be accepted
sudo -u www-data psql -h localhost -U appuser -d company
```

### Key Takeaway
Ident mapping eliminates password-based authentication for trusted local connections. It's convenient but only works for TCP connections where the remote server runs `identd` (rare in modern setups). Prefer `scram-sha-256` for production.


[← Previous](39-pghbaconf-advanced-configuration.md) | [↑ Index](index.md) | [Next →](41-password-encryption.md)
