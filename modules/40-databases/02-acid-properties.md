## ACID Properties

Relational databases guarantee **ACID**:

- **Atomicity** — a transaction completes fully or not at all (no partial writes)
- **Consistency** — data always satisfies constraints (foreign keys, types, CHECK)
- **Isolation** — concurrent transactions don't interfere (controlled by isolation level)
- **Durability** — committed data survives crashes (thanks to **WAL** — Write-Ahead Log)



---

[← Previous](01-relational-databases-rdbms.md) | [↑ Index](index.md) | [Next →](03-relational-vs-nosql.md)
