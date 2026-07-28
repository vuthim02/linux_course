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

### Understanding the Output

```
-Queue ID- --Size-- ----Arrival---- -Sender/Recipient-------
ABCDEF1234    2500  Jun 24 10:00  sender@example.com
              (host unreachable)  recipient@example.org
```

- **Queue ID**: unique identifier for tracking
- **Size**: message size in bytes
- **Arrival**: when the message entered the queue
- **Status**: why it's in the queue (deferred, active, etc.)

### Useful Variations

```bash
# Count total messages in queue
mailq | grep -c '^[0-9A-F]'

# List only active (currently being delivered)
mailq | grep 'active'

# Find messages larger than 1MB
mailq | awk '$2 > 1048576 {print}'
```


[← Previous](35-104-policy-daemon-postfwd-postgrey.md) | [↑ Index](index.md) | [Next →](37-112-flushing-the-queue.md)
