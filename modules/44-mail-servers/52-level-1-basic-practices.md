## ⭐ Level 1: Basic Practices

### Practice 1: Install Postfix as a Satellite

**Goal**: Install Postfix configured to relay all mail through a smarthost.

```bash
sudo apt install postfix
# At the prompt, choose "Satellite system"
# Set smarthost: [smtp.example.com]:587
```

Or reconfigure:

```bash
sudo dpkg-reconfigure postfix

# Verify
postconf -n | grep relayhost
```





[← Previous](51-144-dovecot-sasl-for-postfix.md) | [↑ Index](index.md) | [Next →](53-level-2-intermediary-practices.md)
