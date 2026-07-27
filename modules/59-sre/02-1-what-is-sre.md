## 1. What is SRE?

Site Reliability Engineering is what happens when you ask a software engineer to design an operations team. Coined at Google in 2003 by Ben Treynor Sloss.

### SRE vs DevOps

| Dimension | DevOps | SRE |
|---|---|---|
| Origin | Community movement | Google internal role |
| Focus | Culture, collaboration, pipelines | Reliability, latency, capacity |
| Key metric | Cycle time, deployment frequency | Error budget, SLO compliance |
| Operations | Everyone does ops | SREs cap ops work at 50% |

### The SRE Creed

1. **Hire SREs from software engineering** — they must be able to write code
2. **Error budget** — product owner and SRE agree on how unreliable the service can be
3. **Reduce toil** — no more than 50% of time on manual operations
4. **Monitoring and distributed systems** — deep understanding of the systems being operated

> "The primary payoff of SRE is keeping the service running while maximizing the velocity of feature development." — Google SRE Book

---



---

[← Previous](01-reverse-engineering-approach.md) | [↑ Index](index.md) | [Next →](03-2-service-level-indicators-slis.md)
