## ACID Properties

Relational databases guarantee **ACID**:

- **Atomicity** — a transaction completes fully or not at all (no partial writes)
- **Consistency** — data always satisfies constraints (foreign keys, types, CHECK)
- **Isolation** — concurrent transactions don't interfere (controlled by isolation level)
- **Durability** — committed data survives crashes (thanks to **WAL** — Write-Ahead Log)

### Why ACID Matters

Without ACID, concurrent operations can corrupt data. Imagine two bank transfers debiting the same account simultaneously — without atomicity and isolation, the account could go negative.

### Isolation Levels

| Level | Dirty Read | Non-Repeatable Read | Phantom Read |
|-------|-----------|-------------------|-------------|
| `READ UNCOMMITTED` | Yes | Yes | Yes |
| `READ COMMITTED` | No | Yes | Yes |
| `REPEATABLE READ` | No | No | Yes (InnoDB: No) |
| `SERIALIZABLE` | No | No | No |

```sql
-- Check / set isolation level in MariaDB
SELECT @@transaction_isolation;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

### Key Takeaway
ACID is what separates a relational database from a flat file. For any system where data integrity matters — financial, inventory, user accounts — ACID compliance is non-negotiable.


[← Previous](01-relational-databases-rdbms.md) | [↑ Index](index.md) | [Next →](03-relational-vs-nosql.md)
