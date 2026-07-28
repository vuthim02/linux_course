## 🔍 Section 8: Analyzing Boot Performance

systemd-analyze is a powerful tool for understanding boot time.

```bash
# Total boot time
systemd-analyze

# Time each unit took to start
systemd-analyze blame

# Dependency tree with timings (critical chain)
systemd-analyze critical-chain

# SVG visualization of boot
systemd-analyze plot > boot.svg

# Boot time per service (sorted)
systemd-analyze blame | head -20
```

### Example Output

```
$ systemd-analyze
Startup finished in 2.345s (kernel) + 8.123s (initrd) + 12.456s (userspace) = 22.924s

$ systemd-analyze blame
          5.234s NetworkManager-wait-online.service
          3.456s apt-daily-upgrade.service
          2.123s fstrim.service
          1.456s man-db.service
          1.234s snapd.service
          ...
```





[← Previous](10-section-7-journald-systemds-logging.md) | [↑ Index](index.md) | [Next →](12-section-9-systemd-timers-modern.md)
