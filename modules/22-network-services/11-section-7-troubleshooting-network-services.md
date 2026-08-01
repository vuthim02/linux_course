## 🔍 Section 7: Troubleshooting Network Services

### Troubleshooting Methodology

```
1. CHECK — Is the service running?
   systemctl status service-name

2. CHECK — Is it listening on the right port?
   ss -tlnp | grep PORT

3. CHECK — Is the firewall allowing it?
   sudo ufw status
   sudo firewall-cmd --list-all

4. CHECK — Can localhost connect?
   nc -zv localhost PORT
   curl http://localhost

5. CHECK — Can other hosts connect?
   From client: nc -zv SERVER-IP PORT

6. CHECK — Are logs showing errors?
   journalctl -u service-name -n 50
```

### Common Problems

**Problem 1: Service won't start**

```bash
# Check systemd status
sudo systemctl status service-name

# Check journal for errors
sudo journalctl -xe -u service-name

# Check config syntax
sudo sshd -t               # SSH
sudo apache2ctl configtest  # Apache
sudo nginx -t               # Nginx
sudo dhcpd -t               # DHCP
```

**Problem 2: Service running but not responding**

```bash
# Check if it's listening
ss -tlnp | grep PORT

# Check firewall
sudo ufw status verbose

# Check if bound to wrong interface
ss -tlnp | grep "0.0.0.0:PORT"  # All interfaces
ss -tlnp | grep "127.0.0.1:PORT" # Localhost only

# Check if address already in use
sudo ss -tlnp | grep PORT
```

**Problem 3: DHCP not assigning IPs**

```bash
# Check DHCP server status
sudo systemctl status isc-dhcp-server

# Check config
sudo dhcpd -t

# Check leases
cat /var/lib/dhcp/dhcpd.leases | tail -20

# Check if another DHCP server is on the network (rogue DHCP)
sudo tcpdump -i eth0 port 67 or port 68 -n
```

**Problem 4: Apache not serving pages**

```bash
# Check Apache status
sudo systemctl status apache2

# Check error log
sudo tail -50 /var/log/apache2/error.log

# Check access log
sudo tail -50 /var/log/apache2/access.log

# Check if DocumentRoot exists and has proper permissions
ls -la /var/www/html/

# Check Apache can read the files
sudo -u www-data ls -la /var/www/html/

# Check .htaccess isn't blocking
# Temporarily rename .htaccess to test
```

**Problem 5: SSH connection refused**

```bash
# On server:
sudo systemctl status sshd   # RHEL/Fedora; use "ssh" on Debian/Ubuntu
ss -tlnp | grep 22         # Check if SSH is listening
sudo sshd -t               # Check config
sudo journalctl -u sshd -n 20

# On client:
ssh -vvv user@server       # Verbose debug output
nc -zv server 22           # Check basic connectivity
telnet server 22           # Check raw socket
```





[← Previous](10-level-3-advanced-troubleshooting-and.md) | [↑ Index](index.md) | [Next →](12-practice-section-15-hands-on-exercises.md)
