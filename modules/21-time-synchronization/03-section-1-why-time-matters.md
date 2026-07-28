## 🔍 Section 1: Why Time Matters

### What Depends on Accurate Time?

```bash
# 1. Authentication
# Kerberos requires time within 5 minutes of the server
# SSL/TLS certificates have validity periods (notBefore/notAfter)
# OAuth tokens expire

# 2. Logging and Auditing
# Log timestamps must be accurate for forensics
# Correlating logs across multiple servers requires synchronized time

# 3. Scheduling
# cron jobs run at specific times
# Database backups must align across servers

# 4. Distributed Systems
# Distributed databases (Cassandra, etc.) depend on time ordering
# File timestamps for build systems (make, git)
# Transaction ordering

# 5. Security
# DNSSEC validation
# Certificate revocation lists (CRLs)
# Session timeouts
```

### How Bad Can It Be?

```bash
# Clock off by 1 second:   barely noticeable
# Clock off by 1 minute:   cron jobs start early/late
# Clock off by 1 hour:     log timestamps confusing, cron off by hours
# Clock off by 1 day:      SSL certificates fail ("not yet valid")
# Clock off by 1 year:     everything breaks
```





[← Previous](02-level-1-basic-time-concepts.md) | [↑ Index](index.md) | [Next →](04-section-2-how-ntp-works.md)
