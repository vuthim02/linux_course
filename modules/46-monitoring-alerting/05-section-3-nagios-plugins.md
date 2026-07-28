## 🔍 Section 3: Nagios Plugins

### 3.1 Standard Plugins

| Plugin | Purpose | Example |
|--------|---------|---------|
| `check_ping` | ICMP ping with thresholds | `check_ping -H 10.0.0.1 -w 100,20% -c 200,50%` |
| `check_http` | HTTP/S check with content match | `check_http -H example.com -u /health -s "OK"` |
| `check_ssh` | SSH service check | `check_ssh 10.0.0.10` |
| `check_disk` | Disk usage check | `check_disk -w 20% -c 10% -p /dev/sda1` |
| `check_load` | System load average | `check_load -w 5.0,4.0,3.0 -c 10.0,6.0,4.0` |
| `check_procs` | Process count | `check_procs -w 150 -c 200` |
| `check_swap` | Swap usage | `check_swap -w 50% -c 25%` |
| `check_ntp` | NTP time offset | `check_ntp -H pool.ntp.org -w 0.5 -c 1.0` |
| `check_dns` | DNS resolution | `check_dns -H example.com -s 8.8.8.8` |
| `check_tcp` | TCP port check | `check_tcp -H 10.0.0.10 -p 3306` |
| `check_udp` | UDP service check | `check_udp -H 10.0.0.10 -p 161` |
| `check_smtp` | SMTP service check | `check_smtp -H mail.example.com` |
| `check_mysql` | MySQL connection check | `check_mysql -H 10.0.0.10 -u nagios -p secret` |

### 3.2 Plugin Return Codes

```bash
# Every Nagios plugin must return ONE of these exit codes:

# 0 = OK       — Everything is working fine
# 1 = WARNING  — Something is concerning but not critical
# 2 = CRITICAL — Something is broken, take action
# 3 = UNKNOWN  — Could not determine status

# Examples:
/usr/lib/nagios/plugins/check_ping -H 8.8.8.8 -w 100,20% -c 200,50%
echo $?
# 0 (OK) — ping responded within thresholds

/usr/lib/nagios/plugins/check_disk -w 80% -c 90% -p /
echo $?
# 0 (OK) or 1 (WARNING) or 2 (CRITICAL) depending on disk usage
```

### 3.3 Plugin Output Format

```
Plugin output format:
OK - Description | 'label'=value;warn;crit;min;max

Example output:
OK - Disk / is at 45% used (24GB/53GB) | '/used'=45%;80;90;0;100

Nagios parses:
  - The status text before the pipe: "OK - Disk / is at 45% used (24GB/53GB)"
  - Performance data after the pipe: '/used'=45%;80;90;0;100
  - Performance data is stored in the Nagios status log and can be graphed
```

### 3.4 Writing a Custom Nagios Plugin

```bash
#!/bin/bash
# /usr/lib/nagios/plugins/check_custom_app — Custom Python application health check

# A valid Nagios plugin MUST:
# 1. Print one line of output
# 2. Exit with 0 (OK), 1 (WARNING), 2 (CRITICAL), or 3 (UNKNOWN)

# Check if our app is responding on TCP port 8080
HOST="${1:-127.0.0.1}"
PORT="${2:-8080}"
WARN_THRESHOLD="${3:-2}"
CRIT_THRESHOLD="${4:-5}"

# Measure response time
START=$(date +%s%N)
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}:%{time_total}" \
    --connect-timeout 5 \
    "http://${HOST}:${PORT}/health" 2>/dev/null)
END=$(date +%s%N)
RESPONSE_TIME_MS=$(( (END - START) / 1000000 ))

HTTP_CODE="${RESPONSE%%:*}"
TIME_SECONDS="${RESPONSE##*:}"

if [ "$HTTP_CODE" = "200" ]; then
    STATUS="OK"
    EXIT_CODE=0
elif [ "$HTTP_CODE" = "" ]; then
    STATUS="CRITICAL"
    EXIT_CODE=2
    echo "CRITICAL - Connection to ${HOST}:${PORT} failed"
    exit 2
else
    STATUS="WARNING"
    EXIT_CODE=1
fi

# Compare response time to thresholds
if (( $(echo "$TIME_SECONDS > $CRIT_THRESHOLD" | bc -l) )); then
    STATUS="CRITICAL"
    EXIT_CODE=2
elif (( $(echo "$TIME_SECONDS > $WARN_THRESHOLD" | bc -l) )); then
    STATUS="WARNING"
    EXIT_CODE=1
fi

# Output with performance data
echo "${STATUS} - App on ${HOST}:${PORT} returned HTTP ${HTTP_CODE} in ${TIME_SECONDS}s | 'response_time'=${TIME_SECONDS};${WARN_THRESHOLD};${CRIT_THRESHOLD};0;30 'http_code'=${HTTP_CODE};;;0;599"

exit $EXIT_CODE
```

```bash
# Make it executable
sudo chmod +x /usr/lib/nagios/plugins/check_custom_app

# Test it
/usr/lib/nagios/plugins/check_custom_app 127.0.0.1 8080 2 5
# OK - App on 127.0.0.1:8080 returned HTTP 200 in 0.045s | 'response_time'=0.045;2;5;0;30 'http_code'=200;;;0;599
echo $?
# 0

# Register in Nagios
# In commands.cfg:
# define command {
#     command_name    check_custom_app
#     command_line    /usr/lib/nagios/plugins/check_custom_app $HOSTADDRESS$ $ARG1$ $ARG2$ $ARG3$
# }

# In services.cfg:
# define service {
#     host_name               app-server-01
#     service_description     Custom App Health
#     check_command           check_custom_app!8080!2!5
#     max_check_attempts      3
#     check_interval          1
#     retry_interval          1
#     contact_groups          admins
# }
```

### 3.5 NRPE — Nagios Remote Plugin Executor

```bash
# On the remote host (the one being monitored):
sudo apt update
sudo apt install nagios-nrpe-server nagios-plugins -y

# Configure NRPE daemon
sudo tee /etc/nagios/nrpe.cfg << 'EOF'
server_port=5666
server_address=0.0.0.0
allowed_hosts=127.0.0.1,10.0.0.5
dont_blame_nrpe=0
debug=0
command_timeout=60

command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib/nagios/plugins/check_load -w 5.0,4.0,3.0 -c 10.0,6.0,4.0
command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_swap]=/usr/lib/nagios/plugins/check_swap -w 50% -c 25%
command[check_procs]=/usr/lib/nagios/plugins/check_procs -w 150 -c 200
command[check_ssh]=/usr/lib/nagios/plugins/check_ssh 127.0.0.1
EOF

sudo systemctl restart nagios-nrpe-server
sudo systemctl enable nagios-nrpe-server

# Verify NRPE is listening
sudo ss -tlnp | grep 5666
# LISTEN 0  128  0.0.0.0:5666  0.0.0.0:*  users:(("nrpe",pid=1234,fd=3))
```

```bash
# On Nagios server — test NRPE connection
/usr/lib/nagios/plugins/check_nrpe -H 10.0.0.10 -c check_load
# OK - load average: 0.23, 0.15, 0.10 | load1=0.230;5.000;10.000;0; ...

/usr/lib/nagios/plugins/check_nrpe -H 10.0.0.10 -c check_disk
# OK - Disk / is at 45% used (24GB/53GB) | '/used'=45%;20;10;0;100

# Test what commands NRPE has available
/usr/lib/nagios/plugins/check_nrpe -H 10.0.0.10
# NRPE v4.0.3
```





[← Previous](04-section-2-nagios-core.md) | [↑ Index](index.md) | [Next →](06-section-4-nagios-dependencies-and.md)
