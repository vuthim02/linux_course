## 13.1 Configuration Verification

```bash
# Check for syntax errors
postfix check

# Show effective non-default config
postconf -n
```

### What postfix Check Catches

- Syntax errors in `main.cf` and `master.cf`
- Missing required parameters
- Deprecated parameters
- File permission issues (e.g., key files readable by group)

### Verifying Specific Parameters

```bash
# Show all TLS-related settings
postconf | grep tls

# Show all SASL settings
postconf | grep sasl

# Show all relay settings
postconf | grep relay

# Show master.cf service definitions
postconf -M
```

### Key Takeaway
Run `postfix check` after every configuration change. It catches errors before you restart and potentially break production mail flow.


[← Previous](42-123-log-summaries-with-pflogsumm.md) | [↑ Index](index.md) | [Next →](44-132-smtp-protocol-debugging.md)
