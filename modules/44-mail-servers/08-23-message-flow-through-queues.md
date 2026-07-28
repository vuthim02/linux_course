## 2.3 Message Flow Through Queues

```
pickup ─▶ maildrop/
smtpd ──▶ incoming/ ──▶ cleanup ──▶ qmgr ──▶ active/
                  │                           ├── local delivery
                  │                           ├── smtp delivery
                  │                           └── defer → deferred/
```

### Queue Lifecycle

1. **maildrop/** — Local submissions via `sendmail` command or `pickup`
2. **incoming/** — Messages received from network `smtpd`
3. **cleanup/** — Normalizes headers, adds `Received:`, canonicalizes addresses
4. **qmgr/** — Queue manager reads and groups by destination
5. **active/** — Currently being delivered (limited to 20000)
6. **deferred/** — Failed temporarily (DNS, connection timeout)
7. **hold/** — Frozen by admin or content filter

### Key Takeaway
The `active` queue is a view, not a directory. Files are hard-linked from `incoming` or `deferred`. When you see high `active` counts, it means delivery agents are busy — check for slow destinations.


# 3. Installation


[← Previous](07-22-queue-directories.md) | [↑ Index](index.md) | [Next →](09-31-installing-postfix.md)
