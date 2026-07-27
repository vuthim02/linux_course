## 🔍 Section 7: Tuned — Automated Performance Tuning

`tuned` is a system tuning daemon that applies predefined or custom performance profiles. It adjusts kernel parameters, disk scheduler settings, CPU governor, and more — all from a single profile switch.

```bash
# Install
sudo dnf install tuned      # RHEL/Fedora
sudo apt install tuned      # Debian/Ubuntu

# Enable and start
sudo systemctl enable --now tuned

# List available profiles
tuned-adm list

# Check active profile
tuned-adm active

# Switch to a profile
sudo tuned-adm profile throughput-performance
sudo tuned-adm profile latency-performance
sudo tuned-adm profile powersave
```

### Common Profiles

| Profile | Use Case |
|---------|----------|
| `throughput-performance` | Server workloads — maximizes disk/network throughput |
| `latency-performance` | Low-latency applications — disables power saving |
| `virtual-guest` | VMs — optimizes for virtualization overhead |
| `powersave` | Laptops/energy-efficient — minimizes power consumption |
| `balanced` | Default — good mix of performance and power |

### Creating Custom Profiles

```bash
# Copy an existing profile
sudo cp -r /usr/lib/tuned/throughput-performance /etc/tuned/myprofile

# Edit the tuned.conf
sudo vi /etc/tuned/myprofile/tuned.conf

# Customize sections:
# [cpu] governor=performance
# [disk] elevator=none
# [vm] transparent_hugepages=always
# [sysctl] kernel.numa_balancing=1

# Activate custom profile
sudo tuned-adm profile myprofile
```

`tuned` also supports `tuned-adm recommend` which detects the hardware (bare metal, VM, laptop) and suggests the best profile automatically.

---



---

[← Previous](08-section-6-kernel-parameters.md) | [↑ Index](index.md) | [Next →](10-section-8-perf-linux-profiler.md)
