## 11.1 Viewing the Queue

```bash
# Show queue
mailq
# Alternative
postqueue -p

# Count messages per queue
mailq | tail -n +2 | grep -c '^'

# Show deferred queue only
mailq | grep -A 1 '^[0-9A-F]'
```



---

[← Previous](35-104-policy-daemon-postfwd-postgrey.md) | [↑ Index](index.md) | [Next →](37-112-flushing-the-queue.md)
