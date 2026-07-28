## 10.4 Policy Daemon (postfwd / postgrey)

```bash
# Example with postgrey (greylisting)
smtpd_recipient_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unauth_destination,
  check_policy_service inet:127.0.0.1:10023,
  permit
```

```bash
sudo apt install postgrey
```


# 11. Queue Management




[← Previous](34-103-anvil-rate-limiting-built-in.md) | [↑ Index](index.md) | [Next →](36-111-viewing-the-queue.md)
