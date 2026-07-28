## 1.2 Message Flow

```
MUA ──SMTP──▶ MTA (outbound) ──SMTP──▶ MTA (inbound) ──LMTP/MDA──▶ Mailbox ──IMAP/POP3──▶ MUA
```

Concrete example:

```
Thunderbird ──SMTP:587──▶ Postfix (relay) ──SMTP:25──▶ Postfix (destination)
    │                                                          │
    │                                                     Dovecot IMAP:993
    └───────────────────────────────────────────────────────────┘
```

### Each Hop Explained

1. **MUA → MTA**: User sends email via SMTP (port 587 with auth)
2. **MTA → MTA**: Server relays to the recipient's MX (port 25)
3. **MTA → MDA**: Mail delivered to local storage (LMTP/MDA)
4. **MDA → Mailbox**: Written to Maildir/mbox format on disk
5. **MUA ← Mailbox**: Recipient reads via IMAP or POP3

### Key Takeaway
SMTP is a **store-and-forward** protocol. Each MTA accepts the message, queues it, and forwards it to the next hop. If the next hop is unreachable, the message sits in the deferred queue and retries later.


[← Previous](02-11-vocabulary.md) | [↑ Index](index.md) | [Next →](04-13-envelope-vs-header-vs.md)
