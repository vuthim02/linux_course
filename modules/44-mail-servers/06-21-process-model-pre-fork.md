## 2.1 Process Model (Pre-fork)

Postfix does **not** spawn a new process per connection. The `master` daemon pre-forks a pool of children:

```
master (pid 1 for Postfix)
  ├── smtpd      (incoming SMTP connections)
  ├── pickup     (retrieves local submissions from maildrop)
  ├── cleanup    (canonicalises headers, adds Received)
  ├── qmgr       (queue manager — sorts and schedules deliveries)
  ├── trivial-rewrite (address rewriting, transport maps)
  ├── bounce     (generates bounce messages)
  ├── local      (delivery to local UNIX accounts / mailboxes)
  ├── virtual    (delivery to virtual mailbox domains)
  └── pipe       (delivery via external command)
```

The queue manager (`qmgr`) is the **heart**. It reads the queue directories, groups messages by destination, and hands them off to the appropriate delivery agent (`smtp` for remote, `local` for local, `virtual` for virtual domains).

### Controlling Process Limits

```bash
# /etc/postfix/master.cf — per-service process limits
# Format: service type private unpriv chroot wakeup maxproc command args
smtp      inet  n  -  n  -  -  smtpd
  -o smtpd_client_connection_count_limit=20
  -o smtpd_client_connection_rate_limit=60
```

### Key Takeaway
Understanding the pre-fork model helps troubleshoot: if you see "too many connections" errors, you likely need to increase `maxproc` for `smtpd` in `master.cf`, not `max_connections`.


[← Previous](05-14-message-format-rfc-5322.md) | [↑ Index](index.md) | [Next →](07-22-queue-directories.md)
