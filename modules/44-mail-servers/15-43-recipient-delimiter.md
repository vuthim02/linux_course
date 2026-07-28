## 4.3 Recipient Delimiter

```bash
recipient_delimiter = +
```

Allows `user+tag@domain` — useful for filtering. Postfix strips `+tag` before delivery.

### How It Works

```
To: alice+newsletter@example.com
  → Delivered to: alice@example.com
  → X-Original-To header preserves: alice+newsletter@example.com
```

### Practical Uses

- **Filtering**: `user+work@example.com` vs `user+personal@example.com`
- **Tracking**: Unique address per service: `user+github@example.com`
- **Debugging**: See which address a spammer harvested: `user+leaked-list@example.com`

### Procmail/Sieve Filtering Example

```bash
# In .procmailrc — deliver tagged mail to specific folder
:0
* ^X-Original-To:.*\+newsletter
$MAILDIR/newsletter/
```

### Key Takeaway
The `+` delimiter is a convention, not a standard. Most modern MTAs and mailing lists support it, but some broken systems reject addresses with `+` — test before deploying.


[← Previous](14-42-listening-and-delivery.md) | [↑ Index](index.md) | [Next →](16-44-minimal-working-configuration.md)
