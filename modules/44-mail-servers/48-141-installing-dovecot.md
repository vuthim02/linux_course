## 14.1 Installing Dovecot

```bash
sudo apt install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd
```

### What Gets Installed

| Package | Purpose |
|---------|---------|
| `dovecot-core` | Core daemon and configuration framework |
| `dovecot-imapd` | IMAP protocol support (port 143/993) |
| `dovecot-pop3d` | POP3 protocol support (port 110/995) |
| `dovecot-lmtpd` | LMTP delivery agent (recommended over `local`) |

### Verify Installation

```bash
# Check version
dovecot --version

# Check configuration syntax
doveconf -n

# Start and enable
sudo systemctl enable --now dovecot

# Check it's listening
sudo ss -tlnp | grep dovecot
```


[← Previous](47-135-mail-log-analysis-workflow.md) | [↑ Index](index.md) | [Next →](49-142-basic-dovecot-configuration.md)
