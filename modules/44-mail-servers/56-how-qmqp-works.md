## How QMQP Works

Quick Mail Queue Protocol — a proprietary Postfix protocol for **queue sharing** across multiple machines:

```
Server A (smtpd) ──QMQP──▶ Server B (qmgr)
```

Used in multi-tier setups where front-end MTAs accept mail and a back-end QMGR handles delivery. Configure with:

```bash
# /etc/postfix/master.cf
qmgr      unix  n  -  n  -  1  qmgr
# QMQP on the front-end:
qmqpd     unix  n  -  n  -  1  qmqpd
```

QMQP is rarely used today because modern load balancers handle SMTP traffic directly.

### When QMQP Was Useful

- **Pre-LB era**: Multiple front-end MTAs needed to share a single queue
- **Performance**: QMQP is lighter than SMTP (no conversation overhead)
- **Modern alternative**: HAProxy or nginx stream for load balancing SMTP

### Key Takeaway
Unless you're maintaining a legacy multi-tier mail architecture, you'll never use QMQP. Modern setups use HAProxy or DNS MX-based load balancing instead.


[← Previous](55-postfixs-process-model-prefork-vs.md) | [↑ Index](index.md) | [Next →](57-how-the-queue-manager-sorts.md)
