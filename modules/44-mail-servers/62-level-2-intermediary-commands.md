## ⭐ Level 2: Intermediary Commands

> **Level Goal:** Use intermediate Postfix commands for queue surgery, alias rebuilding, and writing to syslog.

### What You'll Cover
- Rebuilding alias and map databases
- Queue management: flushing, deleting, re-queuing, and holding messages
- Using `postlog` for direct syslog writes

| Command | Purpose |
|---------|---------|
| `postmap <file>` | Build indexed database (.db) from flat file |
| `postalias <file>` | Build alias database |
| `newaliases` | Rebuild `/etc/aliases.db` |
| `postqueue -p` | List queue (same as mailq) |
| `postqueue -f` | Flush queue |
| `postqueue -s <domain>` | Flush mail for a specific domain |
| `postsuper -d <id>` | Delete message |
| `postsuper -d ALL <queue>` | Delete all messages in queue |
| `postsuper -r <id>` | Re-queue message (schedule retry) |
| `postsuper -r ALL` | Re-queue all deferred |
| `postsuper -h <id>` | Hold message |
| `postsuper -H <id>` | Release message |
| `postsuper -s` | Structure check (fixes queue directory symlinks) |
| `postlog -p <priority> <message>` | Write to syslog |


[← Previous](61-level-1-basic-commands.md) | [↑ Index](index.md) | [Next →](63-level-3-advanced-commands.md)
