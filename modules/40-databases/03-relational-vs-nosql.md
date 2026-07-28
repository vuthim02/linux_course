## Relational vs NoSQL

| Aspect | RDBMS (MariaDB/PostgreSQL) | NoSQL (MongoDB, Redis) |
|--------|---------------------------|------------------------|
| Data model | Tables, rows, columns | Documents, key-value, graphs |
| Schema | Fixed (enforced) | Flexible (schema-less) |
| Joins | Native, powerful | Manual or limited |
| ACID | Full | Often BASE (eventually consistent) |
| Scaling | Vertical (scale up) | Horizontal (scale out) |
| Use case | Financial, structured data | Real-time feeds, big data, caching |

### When to Choose Which

- **Choose RDBMS** when: data is structured, relationships matter, you need transactions (banking, inventory, ERP)
- **Choose NoSQL** when: schema is flexible/varies, extreme write throughput, simple key-value access (session stores, IoT telemetry, caching layers)
- **Choose both**: Many production systems use PostgreSQL for core data and Redis for caching/sessions

### BASE (NoSQL Alternative to ACID)

- **Basically Available** — system guarantees availability
- **Soft state** — state may change over time without input
- **Eventually consistent** — data will become consistent after a period without writes

### Key Takeaway
NoSQL isn't "better" — it's a trade-off. RDBMS gives you consistency and relationships; NoSQL gives you scale and flexibility. Most sysadmins work with both.


[← Previous](02-acid-properties.md) | [↑ Index](index.md) | [Next →](04-sql-structured-query-language.md)
