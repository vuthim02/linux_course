## 📋 Prerequisites

| Requirement | Details |
|-------------|---------|
| OS | Ubuntu 22.04 / Debian 12 (or RHEL-equivalent with `dnf`) |
| Access | Root or `sudo` on at least 2 servers (or VMs/containers) |
| Services | A test web server (e.g., `python3 -m http.server 8000`) |
| Tools | `curl`, `netstat`, `tcpdump`, `systemctl` |
| Time | 3–4 hours of hands-on lab work |

### Key Ports to Know

| Port | Service |
|------|---------|
| 3128 | Squid default proxy port |
| 80/443 | HTTP/HTTPS (Nginx/HAProxy) |
| 9090 | HAProxy stats page |
| 8080 | Common alternative HTTP port |


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-forward-proxy-vs.md)
