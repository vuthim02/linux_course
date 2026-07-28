## 🔍 Section 7: Troubleshooting Time Sync

### Common Problems

**Problem 1: Time not synchronized**

```bash
# Check status
timedatectl
# Look for: "System clock synchronized: no"

# Check if NTP service is running
systemctl status chrony || systemctl status systemd-timesyncd

# Check network connectivity to NTP servers
chronyc sources -v
# Or: ntpq -p (if using ntpd)

# Test DNS resolution of NTP servers
host pool.ntp.org
```

**Problem 2: Large time offset**

```bash
# Force immediate sync
sudo chronyc -a makestep

# Check how far off
chronyc tracking | grep "System time"

# If Chromy cannot adjust enough, stop it and set time manually:
sudo systemctl stop chrony
sudo timedatectl set-ntp no
sudo timedatectl set-time "2024-01-15 10:30:00"
sudo timedatectl set-ntp yes
```

**Problem 3: Firewall blocking NTP**

```bash
# NTP uses UDP port 123
# Check if it's open:
nc -zuv pool.ntp.org 123

# Open port 123 for outgoing
sudo ufw allow out 123/udp
# Or for incoming (if you're an NTP server):
sudo ufw allow 123/udp
```

**Problem 4: Virtual machine time drift**

```bash
# VM-specific issues:
# - Host suspension/pause causes time to freeze
# - VM migration can cause jumps
# - Overcommitted CPU causes time to run slow

# Solutions:
# 1. Use Chrony (handles VM pauses better)
# 2. Add to /etc/chrony/chrony.conf:
#    makestep 1.0 -1   # Always step, even large jumps
# 3. Use KVM's virtio-rtc or VMware Tools
```

### Debugging Commands

```bash
# Chrony verbose output
chronyc sources -v
chronyc sourcestats -v

# Check chrony logs
sudo journalctl -u chrony -n 50

# Check if chrony has been stepping the clock
sudo journalctl -u chrony | grep -i "step\|slew"

# Manual NTP query (bypasses Chrony)
ntpdate -q pool.ntp.org
```





[← Previous](10-level-3-advanced-troubleshooting-and.md) | [↑ Index](index.md) | [Next →](12-practice-section-15-hands-on-exercises.md)
