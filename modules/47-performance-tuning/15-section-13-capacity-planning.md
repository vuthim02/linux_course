## 🔍 Section 13: Capacity Planning

### Trend Analysis

Collect performance metrics over time and identify growth patterns:

```bash
# Use sar to collect historical data
sar -u -f /var/log/sysstat/sa20   # CPU from the 20th of month
sar -r -f /var/log/sysstat/sa20   # Memory

# Plot with sadf
sadf -d /var/log/sysstat/sa20 -- -u | column -t -s ';' | less

# For comprehensive trending, use Prometheus + Grafana (monitoring stack)
```

### Forecasting

Simple linear forecasting:

```
Current utilization: 60%
Monthly growth rate: 5%
Threshold: 80% (alarm), 90% (critical)

Months until 80%:  log(80/60) / log(1.05) ≈ 6 months
Months until 90%:  log(90/60) / log(1.05) ≈ 8.5 months
```

### Right-Sizing

| Symptom | Likely Issue | Fix |
|---------|-------------|-----|
| CPU idle 90%, high load | I/O bound | Faster storage |
| High CPU steal | Hypervisor overcommit | Move to dedicated hosts |
| Swap usage growing | Insufficient RAM | Add RAM or reduce allocation |
| Disk 99% util, low IOPS | Wrong storage tier | Upgrade to NVMe |
| Network drops (RX overruns) | Insufficient ring buffers | ethtool -G, increase budget |

### Headroom

Always maintain 20-30% headroom for traffic spikes, deployments, and background tasks:

```
Capacity = Peak Demand × (1 + Headroom)
Example: Peak = 1000 req/s, Headroom = 30%
  → Provision for 1300 req/s
```

### Cloud vs On-Prem Scaling

| Factor | Cloud | On-Prem |
|--------|-------|---------|
| Scaling speed | Minutes (API/provisioning) | Days/weeks (procurement) |
| Granularity | Tiny increments | Fixed hardware sizes |
| Cost model | OpEx (pay for use) | CapEx (buy upfront) |
| Performance consistency | Variable (noisy neighbors) | Predictable (dedicated hardware) |
| Right-sizing risk | Can downsize | Overprovisioning is permanent |





[← Previous](14-section-12-application-tuning.md) | [↑ Index](index.md) | [Next →](16-hands-on-practices.md)
