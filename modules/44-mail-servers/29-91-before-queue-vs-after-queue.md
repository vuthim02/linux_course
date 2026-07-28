## 9.1 Before-Queue vs After-Queue

| Strategy | Filter runs | Impact |
|----------|-------------|--------|
| Before-queue | During SMTP conversation | Reject at connection time (e.g. Postscreen) |
| After-queue | After message is queued | Accept then scan; bounce if spam |

### Comparison

| Aspect | Before-Queue | After-Queue |
|--------|-------------|-------------|
| Reject spam at | Connection time | After acceptance |
| Resource usage | Low (lightweight checks) | High (full message scanning) |
| False positive impact | Legitimate email rejected silently | Legitimate email bounced back |
| Tools | Postscreen, DNSBL checks | Amavis, Rspamd, SpamAssassin |
| Best for | High-volume servers | Small to medium setups |

### Key Takeaway
Before-queue filtering (Postscreen) reduces load by ~80% by dropping known-spam clients before they even speak SMTP. Use both: Postscreen for first-pass, Amavis/Rspamd for content filtering.


[← Previous](28-83-maildir-vs-mbox.md) | [↑ Index](index.md) | [Next →](30-92-after-queue-filtering-with-amavis.md)
