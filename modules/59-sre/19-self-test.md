## Self-Test
1. What is the difference between an SLI and an SLO?
2. Why is 100% the wrong SLO target?
3. Calculate: SLO is 99.99%, 5M requests/day, how many can fail per day?
4. What does a burn rate of 14.4× mean?
5. Name the Four Golden Signals.
6. How does MWMBR prevent false positive alerts?
7. What is the RED method? When would you use it?
8. What is toil? Give three examples.
9. What are the five roles in incident command?
10. What sections must a blameless postmortem include?
11. Write a PromQL query for SLO compliance over 30 days.
12. What burn rate thresholds correspond to fast, medium, and slow?
13. Difference between embedded, consultative, and centralized SRE?
14. How does error budget create shared language between product and SRE?
15. What is the first thing an SRE should do when joining a new service?
**Answers:**
1. SLI = indicator (what you measure); SLO = objective (what you target)
2. Cost approaches infinity, users cannot tell difference, innovation stops
3. 5,000,000 × 0.0001 = **500 requests/day**
4. Budget consumed 14.4× faster than planned; will exhaust in ~2 days
5. Latency, Traffic, Errors, Saturation
6. Requires BOTH short window AND long window to fire — filters transient spikes
7. Rate, Errors, Duration — for **service** monitoring
8. Manual, repetitive, automatable, no enduring value (rebooting servers, manual cert renewal, same alert daily)
9. IC, Ops Lead, Comms Lead, Scribe, SME
10. Summary, Timeline, Root Cause, Contributing Factors, Action Items
11. `sum(increase(http_requests_total{status=~"2.."}[30d])) / sum(increase(http_requests_total[30d]))`
12. Fast: 14.4×, Medium: 6×, Slow: 1.5×
13. Embedded (in product team), Consultative (central advises), Centralized (one team for all)
14. SRE defines cost of unreliability; product decides if features worth spending that cost
15. Find existing dashboards, runbooks, SLOs, and incident history — measure before changing
**Score:** 12/15 correct = ready for Part 60.
*Linux SysAdmin Course | Part 59 of ∞ | Reverse Engineering Approach*
*Previous → Part 58: Secrets Management*
*Next → Part 60: Final Capstone — Production-Grade Infrastructure*
[← Previous](18-whats-coming-in-part-60.md) | [↑ Index](index.md)
