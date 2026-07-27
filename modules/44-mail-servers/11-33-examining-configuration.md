## 3.3 Examining Configuration

**Do not** just open `main.cf` — use the `postconf` command:

```bash
# Show non-default parameters only
postconf -n

# Show ALL parameters with their current values
postconf -d

# Show a single parameter
postconf myhostname

# Show a parameter's default
postconf -d myhostname
```

The `-n` flag is your daily driver. It filters out everything that is still at the compiled-in default.



---

[← Previous](10-32-reconfiguring-postfix.md) | [↑ Index](index.md) | [Next →](12-34-maincf-structure.md)
