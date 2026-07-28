## 4.2 Listening and Delivery

```bash
# What interfaces to listen on
inet_interfaces = all            # listen on all (default)
inet_interfaces = loopback-only  # local delivery only

# What domains this server considers "local" (final destination)
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# What networks are trusted to relay mail through us
mynetworks = 127.0.0.0/8, 10.0.0.0/24

# Relaying all outbound mail through a smarthost
relayhost = [smtp.example.com]:587    # bracket = MX lookup disabled, use A/AAAA
```

### inet_interfaces Options

| Value | Behavior |
|-------|----------|
| `all` | Listen on all interfaces (default) |
| `loopback-only` | Only 127.0.0.1 (local delivery only) |
| `192.168.1.1` | Specific IP only |
| `$myhostname, localhost.$mydomain` | Hostname resolution + loopback |

### Key Takeaway
If your server only delivers mail via a relayhost, set `inet_interfaces = loopback-only`. This reduces attack surface by not exposing port 25 to the internet.


[← Previous](13-41-identity-parameters.md) | [↑ Index](index.md) | [Next →](15-43-recipient-delimiter.md)
