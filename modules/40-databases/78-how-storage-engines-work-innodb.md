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



---

[← Previous](77-practice-15-real-world-integration-complete.md) | [↑ Index](index.md) | [Next →](79-postgresql-process-architecture.md)
