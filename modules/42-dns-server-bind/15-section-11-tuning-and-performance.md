## ⚡ Section 11: Tuning and Performance

```c
options {
    max-cache-size 512m;           // Max cache memory
    max-cache-ttl 86400;           // Max cached record TTL
    recursive-clients 10000;       // Max recursive queries
    tcp-clients 150;               // Max TCP connections
    transfers-in 10;               // Concurrent incoming transfers
    transfers-out 10;              // Concurrent outgoing transfers
    edns-udp-size 1232;            // EDNS UDP size (avoid fragmentation)
    max-udp-size 1232;
    prefetch 10 15;                // Refresh when TTL ≤ 10s

    rate-limit {
        responses-per-second 10;
        queries-per-second 20;
        slip 2;
    };
};
```

BIND 9 uses a **task manager** with N worker threads (default = CPU count). Each query becomes multiple events: parse → cache lookup → recurse → validate → respond.





[← Previous](14-section-10-logging.md) | [↑ Index](index.md) | [Next →](16-section-12-troubleshooting.md)
