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



---

[← Previous](02-11-vocabulary.md) | [↑ Index](index.md) | [Next →](04-13-envelope-vs-header-vs.md)
