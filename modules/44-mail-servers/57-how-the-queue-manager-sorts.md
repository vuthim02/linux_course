## How the Queue Manager Sorts by Destination

The `qmgr` groups messages by destination **domain** (not by recipient). For each destination:

1. Look up transport maps → determine delivery agent (`smtp`, `relay`, `lmtp`, etc.)
2. Check `nexthop` → the actual target host/port
3. Build an **ordered transport pool** — one pool per (transport, nexthop) combo
4. Process messages concurrently, respecting `transport_destination_concurrency_limit` (default 20)

This prevents one slow destination from blocking others. If `mx.example.com` is slow, only that pool is delayed.



---

[← Previous](56-how-qmqp-works.md) | [↑ Index](index.md) | [Next →](58-how-cleanup-canonicalises-addresses.md)
