## 🧠 Deep Understanding

### How BIND Processes Queries (Recursive Resolver)

```
Client query (www.example.com A)
        │
        ▼
┌─────────────────────┐
│ 1. Query validation │  ← allow-query, rate-limit check
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 2. Cache lookup     │  ← Already cached?
└─────────┬───────────┘
     ┌────┴────┐
     │  HIT    │  ← Return cached answer (subtract TTL)
     │ (cache) │
     └─────────┘
          │ MISS
          ▼
┌─────────────────────┐
│ 3. Recursion check  │  ← Is recursion allowed for client?
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 4. Iterative query  │  ← Root → TLD → Authoritative
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 5. DNSSEC validation │  ← Validate RRSIG (if DO bit set)
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 6. Cache result     │  ← Store with TTL
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 7. Return answer    │  ← With AD flag if DNSSEC validated
└─────────────────────┘
```

### Delegation and NS Resolution Flow

```
1. Query root (.) → "Where is .com?"
   → Root returns NS a.gtld-servers.net (+ glue A)

2. Query .com TLD → "Where is example.com?"
   → TLD returns NS ns1.example.com (+ glue A 192.168.1.10)

3. Query ns1.example.com → "What is www.example.com?"
   → Authoritative returns www.example.com A 192.168.1.100

4. Optionally fetch DNSKEY → validate RRSIG

5. Cache and return
```

`dig +trace` shows this exact chain.

### Zone Transfer Protocol

```
Master                          Slave
  │                               │
  │─── NOTIFY (example.com) ─────>│
  │<── SOA query ─────────────────│
  │─── SOA response (serial X) ──>│
  │                               │  (Slave compares serials)
  │<── AXFR/IXFR request ─────────│
  │─── Zone data (TCP 53) ───────>│
  │─── SOA (end of transfer) ────>│
  │                               │  (Slave loads zone)
```

- **AXFR:** Full transfer via TCP, all records sent sequentially
- **IXFR:** Incremental — only changed records (requires journal files)
- **NOTIFY:** Master sends notification; slave checks SOA serial and initiates transfer if needed

### DNSSEC Chain of Trust

```
Root DNSKEY (bind.keys — built-in trust anchor)
  └─ signed by Root KSK
      └─ Root DS for .com
          └─ .com DNSKEY (signed by .com KSK)
              └─ .com DS for example.com
                  └─ example.com DNSKEY
                      ├── KSK (signs DNSKEY set, verified by parent DS)
                      └── ZSK (signs all other records, verified by KSK)

Query flow:
  1. Fetch www.example.com + RRSIG
  2. Fetch example.com DNSKEY
  3. Validate RRSIG with ZSK from DNSKEY
  4. Validate ZSK with KSK (via RRSIG DNSKEY)
  5. Validate KSK with DS from .com
  6. Validate .com DNSKEY with .com DS from root
  7. Root KSK trusted via bind.keys
  → Chain of trust established ✓
```

### BIND Task Manager / Event Loop

BIND 9 uses an internal **task manager** with N worker threads (default = CPU count):

```
┌──────────────────────────────────────────┐
│           Task Manager                    │
│  Task Queue: ┌───┬───┬───┬───┬───┐      │
│              │ T │ T │ T │ T │ T │ ...  │
│              └───┴───┴───┴───┴───┘      │
│        ┌───────┴───────┬───────┘        │
│        ▼               ▼                │
│  ┌──────────┐    ┌──────────┐           │
│  │ Thread 1 │    │ Thread 2 │   ...     │
│  │ (Worker) │    │ (Worker) │           │
│  └──────────┘    └──────────┘           │
│        │               │                │
│  ┌──────────┐    ┌──────────┐           │
│  │ Socket   │    │ Socket   │           │
│  │ I/O      │    │ I/O      │           │
│  └──────────┘    └──────────┘           │
└──────────────────────────────────────────┘
```

Each query becomes multiple **events** dispatched within a task:
1. Parse incoming query
2. Cache lookup (non-blocking)
3. If recursion: dispatch upstream sub-queries
4. Wait for responses (async I/O)
5. Validate DNSSEC
6. Cache and respond

This non-blocking event model allows BIND to handle thousands of concurrent queries with few threads.

---



---

[← Previous](18-section-14-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](20-whats-coming-in-part-43.md)
