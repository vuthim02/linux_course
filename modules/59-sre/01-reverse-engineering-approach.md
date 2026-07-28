## Reverse Engineering Approach

We learn SRE backwards: start with a **broken production service** and work upward. You are the on-call engineer at 03:00. Alerts are firing. Users cannot check out. Every concept in this part exists because something _actually broke_ in a real system at scale.

### Why Start With a Incident?

SRE is not theoretical — it is a discipline born from real production failures. By starting with the incident and reasoning backward, you naturally discover:

- **SLIs and SLOs** — the checkout page timed out; how do we define "healthy"?
- **Error budgets** — we burned through 0.1% allowed errors in 20 minutes; what now?
- **Toil** — the fix requires SSHing into 12 servers manually; this should be automated
- **Postmortems** — root cause was a config change; how do we prevent recurrence?
- **Capacity planning** — traffic spiked 3x during the flash sale; did we forecast this?

### The Scenario

A Flask API behind an ALB is returning 5xx errors. PostgreSQL is saturated. Redis cache hit rate dropped to 12%. Latency P99 spiked from 200ms to 14s. The on-call rotation paged you. Your job: restore service, then build the systems to prevent this from happening again.

### How to Use This Part

Each section answers a question that naturally arises during incident response. Read in order or jump to the concept you need. The hands-on practices put you in realistic on-call scenarios.





[↑ Index](index.md) | [Next →](02-1-what-is-sre.md)
