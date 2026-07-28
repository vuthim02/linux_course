## 3.4 main.cf Structure

```
# This is a comment
parameter = value
parameter = value1, value2    # comma or whitespace separated
parameter = $other_param      # variable expansion
parameter =                   # empty value (resets to default)
```

### Key Rules

- Parameters are **case-sensitive**: `myhostname` ≠ `MyHostname`
- Use `$variable` to reference other parameters (e.g., `myorigin = $mydomain`)
- Set a parameter to empty string to reset it to default
- Changes require `postfix reload` (not restart)

### Modifying Parameters

```bash
# Method 1: postconf -e (recommended)
postconf -e "myhostname = mail.example.com"

# Method 2: Direct edit (requires manual reload)
sudo nano /etc/postfix/main.cf
sudo postfix reload
```


# ⭐ Level 2: Intermediary — Configuration and Daily Management

# 4. Basic Configuration


[← Previous](11-33-examining-configuration.md) | [↑ Index](index.md) | [Next →](13-41-identity-parameters.md)
