## 🔍 Section 3: Using timedatectl

`timedatectl` is part of systemd and is the primary tool for managing time and date.

```bash
# Show current time settings
timedatectl

# Output:
#                Local time: Mon 2024-01-15 10:30:45 EST
#            Universal time: Mon 2024-01-15 15:30:45 UTC
#                  RTC time: Mon 2024-01-15 15:30:45
#                 Time zone: America/New_York (EST, -0500)
# System clock synchronized: yes
#               NTP service: active
#           RTC in local TZ: no
```

### Setting Time Zone

```bash
# List all time zones
timedatectl list-timezones

# Filter timezones by region
timedatectl list-timezones | grep -i "america"
timedatectl list-timezones | grep -i "europe"

# Set time zone
sudo timedatectl set-timezone America/New_York
sudo timedatectl set-timezone UTC          # Servers often use UTC

# Check current timezone
timedatectl | grep "Time zone"
```

### Setting Time Manually

```bash
# Set date and time (when NTP is disabled)
sudo timedatectl set-ntp no               # Disable NTP first
sudo timedatectl set-time "2024-01-15 10:30:00"
sudo timedatectl set-ntp yes              # Re-enable NTP
```

### Managing NTP

```bash
# Check if NTP is active
timedatectl | grep "NTP service"

# Enable NTP (starts systemd-timesyncd or chronyd)
sudo timedatectl set-ntp yes

# Disable NTP
sudo timedatectl set-ntp no
```

### RTC (Hardware Clock)

```bash
# Show RTC (hardware clock) settings
timedatectl | grep "RTC"

# Set RTC to use UTC (recommended)
sudo timedatectl set-local-rtc 0

# Set RTC to use local time (not recommended for servers)
sudo timedatectl set-local-rtc 1

# Sync system clock to hardware clock
sudo hwclock -w

# Sync hardware clock to system clock
sudo hwclock -s
```





[← Previous](04-section-2-how-ntp-works.md) | [↑ Index](index.md) | [Next →](06-level-2-intermediary-chrony-configuration.md)
