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

### What Gets Installed

| Package | Purpose |
|---------|---------|
| `postfix` | Main MTA daemon |
| `mailutils` | GNU mail utilities (`mail`, `from`, `headers`) |
| `libsasl2-modules` | SASL authentication modules |

### Verify Installation

```bash
# Check Postfix is running
sudo systemctl status postfix

# Check it's listening on port 25
sudo ss -tlnp | grep :25

# Send a test message
echo "Postfix is working" | mail -s "Test" root
```

### Key Takeaway
"Internet Site" is the right choice for learning. Switch to "Satellite System" later if you want to relay through a smarthost (e.g., your ISP's mail server or a service like SendGrid).


[← Previous](08-23-message-flow-through-queues.md) | [↑ Index](index.md) | [Next →](10-32-reconfiguring-postfix.md)
