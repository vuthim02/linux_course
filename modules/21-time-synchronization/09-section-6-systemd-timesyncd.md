## 🔍 Section 6: systemd-timesyncd

Some lightweight systems use `systemd-timesyncd` instead of Chrony.

```bash
# Check if timesyncd is active
systemctl status systemd-timesyncd

# Configuration
cat /etc/systemd/timesyncd.conf
```

```
[Time]
NTP=0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org
FallbackNTP=ntp.ubuntu.com
RootDistanceMax=5
PollIntervalMin=32
PollIntervalMax=2048
```

### Timesyncd vs Chrony

| Feature | timesyncd | Chrony |
|---------|-----------|--------|
| Complexity | Very simple | Full-featured |
| Server mode | No | Yes |
| NTP peer support | No | Yes |
| Client monitoring | `timedatectl` only | `chronyc` |
| Accuracy | Good | Excellent |
| Best for | Desktops, simple servers | Servers, infrastructure |





[← Previous](08-section-5-configuring-chrony-as.md) | [↑ Index](index.md) | [Next →](10-level-3-advanced-troubleshooting-and.md)
