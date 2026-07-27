## 9.1 Before-Queue vs After-Queue

| Strategy | Filter runs | Impact |
|----------|-------------|--------|
| Before-queue | During SMTP conversation | Reject at connection time (e.g. Postscreen) |
| After-queue | After message is queued | Accept then scan; bounce if spam |



---

[← Previous](28-83-maildir-vs-mbox.md) | [↑ Index](index.md) | [Next →](30-92-after-queue-filtering-with-amavis.md)
