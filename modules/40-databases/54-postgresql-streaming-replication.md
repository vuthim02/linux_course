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


# 13. Database Monitoring




[← Previous](53-mariadb-replication.md) | [↑ Index](index.md) | [Next →](55-mariadb-monitoring.md)
