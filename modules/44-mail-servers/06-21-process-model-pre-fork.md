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



---

[← Previous](05-14-message-format-rfc-5322.md) | [↑ Index](index.md) | [Next →](07-22-queue-directories.md)
