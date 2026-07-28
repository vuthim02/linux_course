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


# 📋 Command Reference




[← Previous](78-how-storage-engines-work-innodb.md) | [↑ Index](index.md) | [Next →](80-mariadbmysql-vs-postgresql-commands.md)
