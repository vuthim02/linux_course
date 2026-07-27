## 3.1 Installing Postfix

```bash
# Debian / Ubuntu
sudo apt update
sudo apt install postfix

# During install you will be prompted for "General type of mail configuration":
#   No Configuration   — no config at all
#   Internet Site      — send/receive directly (recommended for learning)
#   Satellite System   — relay all mail through a smarthost
#   Local Only         — deliver locally only
#
# Choose "Internet Site" and set "System mail name" to your domain.
```



---

[← Previous](08-23-message-flow-through-queues.md) | [↑ Index](index.md) | [Next →](10-32-reconfiguring-postfix.md)
