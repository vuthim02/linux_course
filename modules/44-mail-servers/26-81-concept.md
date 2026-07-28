## 8.1 Concept

Virtual mailboxes store mail **on disk** without requiring a Unix user account per recipient. This is how hosting providers give everyone their own mailbox under the same domain.

### Why Virtual Mailboxes?

| Approach | Pros | Cons |
|----------|------|------|
| System users | Simple, PAM-based | One Unix account per mailbox, scales poorly |
| Virtual mailbox domains | Thousands of mailboxes, no system accounts | More configuration, requires `virtual` transport |

### How It Works

```
Postfix receives mail for user@vdomain.com
  → Looks up virtual_mailbox_domains
  → Looks up virtual_mailbox_maps (user → /path/to/mailbox)
  → Delivers via virtual transport agent
  → Mailbox lives under /var/mail/vdomain/user/
```

### Key Takeaway
Virtual mailboxes are the standard approach for any mail server hosting multiple domains or more than a handful of users.


[← Previous](25-72-virtual-alias-domains.md) | [↑ Index](index.md) | [Next →](27-82-configuration.md)
