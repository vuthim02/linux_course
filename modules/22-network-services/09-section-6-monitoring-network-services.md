## 🔍 Section 6: Monitoring Network Services

### Service Monitoring

```bash
# Check service health
systemctl is-active sshd        # Returns active/inactive
systemctl is-enabled sshd       # Returns enabled/disabled
systemctl is-failed sshd        # Returns failed/active

# Check if port is responding
nc -zv localhost 22
nc -zv localhost 80

# Check if service is accepting connections
curl -I http://localhost

# Monitor logs (use sudo for full access)
sudo journalctl -u sshd -n 20 --no-pager
sudo journalctl -u apache2 -n 20 --no-pager
sudo journalctl -u isc-dhcp-server -n 20 --no-pager

# Follow logs in real-time
sudo journalctl -u sshd -f
```

### Resource Monitoring

```bash
# Check process resource usage
ps aux | grep sshd
ps aux | grep apache2

# Check memory usage
systemd-cgtop

# Check open files per service
sudo lsof -i :22
sudo lsof -i :80
```





[← Previous](08-section-5-securing-network-services.md) | [↑ Index](index.md) | [Next →](10-level-3-advanced-troubleshooting-and.md)
