## Section 10: TCO Modeling and SRE Team Structures

### TCO (Total Cost of Ownership) Modeling for Infrastructure

| Cost Category | Components | % of TCO |
|--------------|------------|----------|
| Compute | Instances, containers, serverless | 30–40% |
| Storage | Block, object, backup | 10–20% |
| Network | Bandwidth, load balancers, NAT | 5–10% |
| Operations | Staff, monitoring, tooling | 20–30% |
| Compliance | Audits, certifications | 5–10% |

**Key formula**: TCO = Capex + Opex over N years.

### SRE Team Structures

| Model | Description | Best For |
|-------|------------|----------|
| **Embedded** | SREs sit within dev teams | Small orgs |
| **Pooled/Central** | Central SRE team services all dev | Standardization |
| **Hybrid** | Core SRE team + embedded liaisons | Mid-to-large orgs |
| **Consulting** | SREs as internal consultants | Org transformation |

### SRE Adoption Patterns

1. **Wheel of Misfortune** — Rotating on-call with dev teams
2. **Error Budgets** — 99.9% × 30 days = 43 min downtime allowed
3. **SLIs/SLOs/SLAs** — Define measurable targets
4. **Toil Automation** — Automate manual ops work
5. **Blameless Postmortems** — Focus on systems, not people
