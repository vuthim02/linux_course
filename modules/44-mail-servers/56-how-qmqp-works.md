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



---

[← Previous](55-postfixs-process-model-prefork-vs.md) | [↑ Index](index.md) | [Next →](57-how-the-queue-manager-sorts.md)
