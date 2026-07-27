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



---

[← Previous](29-initial-configuration.md) | [↑ Index](index.md) | [Next →](31-authentication-methods.md)
