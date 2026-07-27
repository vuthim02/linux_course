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



---

[← Previous](39-pghbaconf-advanced-configuration.md) | [↑ Index](index.md) | [Next →](41-password-encryption.md)
