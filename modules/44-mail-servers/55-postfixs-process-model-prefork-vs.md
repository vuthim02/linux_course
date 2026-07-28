## Postfix's Process Model: Prefork vs Pipelining

Postfix uses a **prefork** model: the `master` daemon starts a configurable number of child processes for each service:

```bash
# /etc/postfix/master.cf
smtp      inet  n  -  y  -  -     smtpd
#                       ^  ^
#                       |  maxproc (blank = default 100)
#                       reserved (always - for smtpd)
```

Key points:
- Children are created at startup and reused for many connections
- Unlike Apache's prefork (one process per connection), Postfix's children handle **one connection at a time** but are reused
- `default_process_limit` (100) governs children per service
- `smtpd_client_connection_count_limit` governs per-IP limits

Postfix also supports **pipelining** at the SMTP level (RFC 2920): clients can send multiple commands without waiting for responses. Enable with:

```bash
smtp_pix_workarounds = *
```




[← Previous](54-level-3-advanced-practices.md) | [↑ Index](index.md) | [Next →](56-how-qmqp-works.md)
