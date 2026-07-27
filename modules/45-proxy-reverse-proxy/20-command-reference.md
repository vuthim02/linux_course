## 📋 Command Reference

### Squid Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install squid` | Install Squid |
| `sudo systemctl {start\|stop\|restart\|reload\|status} squid` | Service management |
| `squid -v` | Show version |
| `squid -k parse` | Validate config |
| `squid -k check` | Check config (same as parse) |
| `squid -k reconfigure` | Reload config without restart |
| `squid -k rotate` | Rotate logs |
| `squid -k shutdown` | Graceful shutdown |
| `squidclient -h HOST -p PORT mgr:info` | Get cache statistics |
| `squidclient -h HOST -p PORT mgr:objects` | List cached objects |
| `squidclient -h HOST -p PORT mgr:storedir` | Storage directory info |
| `sudo tail -f /var/log/squid/access.log` | Watch live requests |
| `sudo tail -f /var/log/squid/cache.log` | Watch daemon messages |
| `squidanalyzer -f /var/log/squid/access.log` | Generate analysis report |

### Nginx Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install nginx` | Install Nginx |
| `sudo systemctl {start\|stop\|restart\|reload\|status} nginx` | Service management |
| `nginx -v` | Show version |
| `nginx -V` | Show version + compile flags |
| `nginx -t` | Validate config syntax |
| `sudo nginx -s reload` | Reload config (graceful) |
| `sudo nginx -s quit` | Graceful shutdown |
| `sudo tail -f /var/log/nginx/access.log` | Watch access log |
| `sudo tail -f /var/log/nginx/error.log` | Watch error log |
| `sudo rm -rf /var/cache/nginx/*` | Clear all cache |
| `sudo find /var/cache/nginx -type f -delete` | Clear cache files |

### HAProxy Commands

| Command | Purpose |
|---------|---------|
| `sudo apt install haproxy` | Install HAProxy |
| `sudo systemctl {start\|stop\|restart\|reload\|status} haproxy` | Service management |
| `haproxy -v` | Show version |
| `haproxy -f /etc/haproxy/haproxy.cfg -c` | Validate config |
| `haproxy -f /etc/haproxy/haproxy.cfg -d` | Start in debug mode (foreground) |
| `sudo haproxy -f /etc/haproxy/haproxy.cfg -sf $PID` | Graceful reload with existing PID |
| `echo "show info" \| sudo socat stdio /run/haproxy/admin.sock` | Show runtime info |
| `echo "show stat" \| sudo socat stdio /run/haproxy/admin.sock` | Show statistics |
| `echo "show table" \| sudo socat stdio /run/haproxy/admin.sock` | Show stick-tables |
| `echo "disable server web_back/web1" \| sudo socat stdio /run/haproxy/admin.sock` | Disable a server |
| `echo "enable server web_back/web1" \| sudo socat stdio /run/haproxy/admin.sock` | Enable a server |
| `echo "set weight web_back/web1 50" \| sudo socat stdio /run/haproxy/admin.sock` | Change server weight |
| `echo "clear table web_back" \| sudo socat stdio /run/haproxy/admin.sock` | Clear stick-table |

### Network Testing Commands

| Command | Purpose |
|---------|---------|
| `curl -x http://proxy:3128 -v http://example.com` | Test forward proxy |
| `curl -sI http://example.com \| grep -i via` | Check Via header |
| `curl -sI http://example.com \| grep -i x-cache` | Check X-Cache header |
| `curl -s -H "Host: app.test" http://127.0.0.1/` | Test reverse proxy with Host header |
| `for i in $(seq 1 10); do curl -s http://lb/ \| grep Server; done` | Test load distribution |
| `tcpdump -i eth0 port 3128 -X` | Capture proxy traffic |
| `ss -tlnp \| grep -E "(squid|nginx|haproxy)"` | Check listening ports |
| `nc -vz 127.0.0.1 3128` | Test TCP connectivity to proxy |

---



---

[← Previous](19-deep-understanding.md) | [↑ Index](index.md) | [Next →](21-whats-coming-in-part-46.md)
