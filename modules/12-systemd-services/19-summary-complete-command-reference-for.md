## 📋 Summary — Complete Command Reference for Part 12

### Level 1: Basic Commands — Service Management

| Command | Action |
|---------|--------|
| `systemctl start NAME` | Start a service |
| `systemctl stop NAME` | Stop a service |
| `systemctl restart NAME` | Restart a service |
| `systemctl reload NAME` | Reload config without restart |
| `systemctl status NAME` | Show detailed status |
| `systemctl enable NAME` | Enable at boot |
| `systemctl disable NAME` | Disable at boot |
| `systemctl enable --now NAME` | Enable and start |
| `systemctl is-active NAME` | Check if running |
| `systemctl is-enabled NAME` | Check if enabled at boot |
| `systemctl mask NAME` | Prevent any start |
| `systemctl unmask NAME` | Restore after mask |
| `systemctl --failed` | Show all failed units |

### Level 2: Intermediary Commands — Listing, Journalctl, Timers

**Listing and Querying**

| Command | Action |
|---------|--------|
| `systemctl list-units` | List all active units |
| `systemctl list-unit-files` | List all unit files |
| `systemctl list-dependencies NAME` | Show dependency tree |
| `systemctl list-timers` | Show timer units |
| `systemctl get-default` | Show default target |
| `systemctl set-default NAME` | Set default target |
| `systemctl isolate NAME` | Switch to target now |

**Service File Sections**

| Section | Contains |
|---------|----------|
| `[Unit]` | Description, dependencies, ordering |
| `[Service]` | ExecStart, User, Restart, limits |
| `[Install]` | WantedBy, RequiredBy |

**Journalctl**

| Command | Action |
|---------|--------|
| `journalctl` | Show all logs |
| `journalctl -u NAME` | Logs for a specific unit |
| `journalctl -f` | Follow new entries |
| `journalctl -n N` | Show last N lines |
| `journalctl -b` | Current boot only |
| `journalctl -b -1` | Previous boot |
| `journalctl --since TIME` | Since a specific time |
| `journalctl -p PRIORITY` | Filter by priority |
| `journalctl --disk-usage` | Show journal size |

**systemd-analyze**

| Command | Action |
|---------|--------|
| `systemd-analyze` | Show boot time |
| `systemd-analyze blame` | Time per service |
| `systemd-analyze critical-chain` | Dependency timing |
| `systemd-analyze plot` | SVG visualization |

### Level 3: Advanced Commands (No additional commands — see debugging and resource control sections above)





[← Previous](18-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](20-whats-coming-in-part-13.md)
