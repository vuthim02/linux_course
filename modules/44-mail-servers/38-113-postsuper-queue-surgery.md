## 11.3 Postsuper (Queue Surgery)

```bash
# Delete a message
postsuper -d ABCDEF1234

# Delete ALL messages in deferred
postsuper -d ALL deferred

# Re-queue a message (schedule for immediate delivery)
postsuper -r ABCDEF1234

# Re-queue ALL deferred
postsuper -r ALL deferred

# Hold a message
postsuper -h ABCDEF1234

# Release a held message
postsuper -H ABCDEF1234
```



---

[← Previous](37-112-flushing-the-queue.md) | [↑ Index](index.md) | [Next →](39-114-queue-lifecycle-monitoring.md)
