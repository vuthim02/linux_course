## 11.2 Flushing the Queue

```bash
# Attempt immediate delivery of all queued mail
postqueue -f

# Flush only one destination
postqueue -s example.com
```

### When to Flush

- After fixing DNS resolution issues
- After bringing a backup MX back online
- After changing the relay host
- After fixing firewall rules

### Monitoring Flush Progress

```bash
# Watch queue count decrease in real-time
watch -n 5 'mailq | tail -1'

# Check what's still deferred
mailq | grep -c 'deferred'
```

### Key Takeaway
`postqueue -f` doesn't delete messages — it just tells Postfix to retry delivery immediately. Messages that fail again will go back to the deferred queue with exponential backoff.


[← Previous](36-111-viewing-the-queue.md) | [↑ Index](index.md) | [Next →](38-113-postsuper-queue-surgery.md)
