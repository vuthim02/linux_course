## 1. Why Monitor?

Monitoring is the act of collecting, analyzing, and acting on system metrics. It answers three questions:

| Question | Example |
|---|---|
| What is happening right now? | CPU at 95%, swap filling up |
| What happened before? | OOM killer fired at 03:14, load spiked |
| What will happen? | Disk fills in 6 days at current rate |

### Use Cases

- **Baselining:** Record "normal" metric ranges so anomalies stand out.
- **Capacity Planning:** Trend disk, memory, and CPU over weeks to predict when you need to scale.
- **Incident Response:** When a service goes down, monitoring tells you which resource was exhausted.
- **Performance Tuning:** Identify exactly which subsystem is the bottleneck.
- **SLA Validation:** Prove that your systems met uptime and latency targets.

### The Observation Pyramid

```
   ┌─────────────┐
   │  Business   │  ← Revenue, signups, latency p99
   ├─────────────┤
   │ Application │  ← Request rate, error rate, GC pauses
   ├─────────────┤
   │   System    │  ← CPU, memory, disk, network (THIS PART)
   ├─────────────┤
   │   Hardware  │  ← S.M.A.R.T., IPMI, fan speed
   └─────────────┘
```

This part covers the **System** layer. You monitor hardware to detect impending failure, system resources to detect exhaustion, and applications to detect logic bugs.





[← Previous](03-level-1-basic-using-built-in.md) | [↑ Index](index.md) | [Next →](05-2-proc-and-sys-the.md)
