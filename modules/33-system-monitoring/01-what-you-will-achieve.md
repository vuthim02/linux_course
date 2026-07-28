## 🎯 What You Will Achieve

| Level | Outcome |
|-------|---------|
| **Basic** | Monitor CPU, memory, disk, and network using built-in tools (`top`, `free`, `ps`, `ss`); understand `/proc/stat`, `/proc/meminfo`, `/proc/loadavg` |
| **Intermediary** | Diagnose bottlenecks with `vmstat`, `iostat`, `mpstat`, `dstat`, `nmon`, `glances`; monitor logs and sockets; use `sar` for historical analysis |
| **Advanced** | Deploy Prometheus + `node_exporter`; interpret S.M.A.R.T. data and RAID health; understand I/O schedulers and `%util` internals; build automated health reporting |

### Why This Part Matters
You can't fix what you can't see. Monitoring is the difference between knowing a server is struggling and finding out when users complain. This part builds from reading `top` to deploying a full Prometheus stack with alerts — the skills that separate reactive firefighting from proactive operations.

> **Real-world perspective**: The best sysadmins know about problems before users do. A server running out of disk space, a process leaking memory, or a network interface dropping packets — all of these show warning signs hours before they cause an outage. Monitoring catches those signs.

**Skills progression in this part**:
- **Basic**: Use `top`, `free`, `ps`, and `ss` for real-time monitoring. Read `/proc/stat`, `/proc/meminfo`, `/proc/loadavg` to understand what the numbers mean. Apply the USE method (Utilization, Saturation, Errors) systematically.
- **Intermediary**: Diagnose bottlenecks with `vmstat`, `iostat`, `mpstat`, `dstat`. Use `sar` for historical performance analysis. Monitor network sockets and log files.
- **Advanced**: Deploy Prometheus with `node_exporter` for metrics collection. Build Grafana dashboards for visualization. Interpret S.M.A.R.T. data for predictive disk failure. Configure Alertmanager for automated notifications.


[↑ Index](index.md) | [Next →](02-table-of-contents.md)
