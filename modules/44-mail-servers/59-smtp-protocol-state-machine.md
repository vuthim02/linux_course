## SMTP Protocol State Machine

```
         ┌──────────────────────────────┐
         │      WAITING FOR CONNECTION   │
         │        220 greeting           │
         └──────────────┬───────────────┘
                        │
                   HELO / EHLO
                        │
         ┌──────────────▼───────────────┐
         │          GOT HELO             │
         │        250 greeting           │
         └──────────────┬───────────────┘
                        │
                   MAIL FROM
                        │
         ┌──────────────▼───────────────┐
         │       GOT MAIL FROM           │
         │        250 sender ok          │
         └──────────────┬───────────────┘
                        │
                   RCPT TO (one or more)
                        │
         ┌──────────────▼───────────────┐
         │       GOT RCPT TO(s)          │
         │        250 recipient ok       │
         └──────────────┬───────────────┘
                        │
                       DATA
                        │
         ┌──────────────▼───────────────┐
         │          GOT DATA             │
         │   354 start mail input        │
         └──────────────┬───────────────┘
                        │
                   Body + "."
                        │
         ┌──────────────▼───────────────┐
         │        MESSAGE ACCEPTED       │
         │      250 queued as <id>       │
         └──────────────┬───────────────┘
                        │
                 QUIT / RSET
                        │
         ┌──────────────▼───────────────┐
         │        221 Bye / start over   │
         └──────────────────────────────┘
```

Each state enforces specific checks (HELO hostname validity, sender domain, recipient access). The `smtpd` child process resets to the GOT HELO state after `RSET`.




[← Previous](58-how-cleanup-canonicalises-addresses.md) | [↑ Index](index.md) | [Next →](60-dkim-signing-basics-opendkim.md)
