## 2.2 Queue Directories

All queues live under `/var/spool/postfix/`:

| Directory | Purpose |
|-----------|---------|
| `maildrop/` | Local submissions (setuid, world-writable) |
| `incoming/` | Messages received from the network |
| `active/` | Messages being processed right now (limited) |
| `deferred/` | Messages that failed temporarily |
| `hold/` | Messages held by admin (or content filter) |
| `bounce/` | Bounce message templates |
| `corrupt/` | Unreadable messages |

The **active** queue is a view — files are hardlinked from `incoming` or `deferred`. The `qmgr` limits active messages to prevent resource exhaustion (default: 20000).

### Queue File Format

Each queue file is a binary file containing:
- The message content (headers + body)
- Metadata: sender, recipients, size, arrival time
- Delivery status and retry information

### Key Takeaway
Never manually edit files in queue directories. Use `postsuper` for queue surgery — manually editing queue files will corrupt Postfix's internal state.


[← Previous](06-21-process-model-pre-fork.md) | [↑ Index](index.md) | [Next →](08-23-message-flow-through-queues.md)
