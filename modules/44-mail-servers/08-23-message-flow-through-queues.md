## 2.3 Message Flow Through Queues

```
pickup ─▶ maildrop/
smtpd ──▶ incoming/ ──▶ cleanup ──▶ qmgr ──▶ active/
                  │                           ├── local delivery
                  │                           ├── smtp delivery
                  │                           └── defer → deferred/
```

---

# 3. Installation



---

[← Previous](07-22-queue-directories.md) | [↑ Index](index.md) | [Next →](09-31-installing-postfix.md)
