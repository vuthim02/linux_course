## 🛠️ 15 Hands-On Practices


### 📘 Level 1 Practices: DNS Fundamentals and Local Resolution

Practice tracing DNS resolution, creating local hostname overrides, and experimenting with resolver configuration.

### ✅ Practice 1: Trace a DNS Resolution Step by Step with dig +trace

```bash
mkdir -p ~/linux-course/part27
cd ~/linux-course/part27

# Trace the full resolution chain
dig +trace www.example.com > trace_output.txt

# Analyze the output
cat trace_output.txt

# Count the steps
echo "Number of resolution steps:"
grep -c "received" trace_output.txt

# Identify root servers contacted
grep "root-servers.net" trace_output.txt
```


### ✅ Practice 2: Create Local Hostname Overrides in /etc/hosts

```bash
cd ~/linux-course/part27

# Backup hosts file
sudo cp /etc/hosts /etc/hosts.backup

# Add a local override
echo "127.0.0.1    mytest.local" | sudo tee -a /etc/hosts

# Verify with getent (uses nsswitch → includes /etc/hosts)
getent hosts mytest.local

# Verify dig bypasses it (queries DNS directly, not /etc/hosts)
dig +short mytest.local

# Remove the entry
sudo sed -i '/mytest.local/d' /etc/hosts
```


### ✅ Practice 3: Experiment with /etc/resolv.conf

```bash
cd ~/linux-course/part27

# Save current resolv.conf
cp /etc/resolv.conf resolv.conf.backup

# Check if it's a symlink
ls -la /etc/resolv.conf

# Show the actual content
cat /etc/resolv.conf

# Show the upstream DNS (if using systemd-resolved)
cat /run/systemd/resolve/resolv.conf 2>/dev/null || echo "Not using systemd-resolved"

# Test resolution speed
time dig google.com +short

# Restore
cp resolv.conf.backup /etc/resolv.conf 2>/dev/null || true
```



### 📘 Level 2 Practices: Resolution Configuration, Caching, and Troubleshooting

Configure search domains, compare resolvers, set up caching with nscd and Unbound, debug with strace, and test mDNS.

### ✅ Practice 4: Set Up a Custom Search Domain

```bash
cd ~/linux-course/part27

# Create a test resolv.conf with search domain
cat > test-resolv.conf << 'EOF'
search lab.example.com prod.example.com
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Test with a single-label name (no dots)
# First with default resolver
dig +short server  # Will fail normally

# Then with our custom search
dig +short server +search  # Will try server.lab.example.com

# Simulate the search order
time dig @8.8.8.8 server.lab.example.com +short
time dig @8.8.8.8 server.prod.example.com +short
```


### ✅ Practice 5: Query Every DNS Record Type

```bash
cd ~/linux-course/part27

# Create a report of all record types for a domain
DOMAIN="google.com"

echo "=== DNS Records for $DOMAIN ===" > dns_records_report.txt
echo "" >> dns_records_report.txt

for type in A AAAA MX NS CNAME TXT SOA; do
    echo "--- $type Records ---" >> dns_records_report.txt
    dig +short $DOMAIN $type >> dns_records_report.txt
    echo "" >> dns_records_report.txt
done

cat dns_records_report.txt
```


### ✅ Practice 6: Compare Resolvers — Google, Cloudflare, Quad9

```bash
cd ~/linux-course/part27

# Test different public resolvers
for resolver in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do
    echo "=== Testing $resolver ==="
    
    # Query time
    TIME=$( (time dig @$resolver google.com +short > /dev/null) 2>&1 | grep real | awk '{print $2}')
    
    # Answer
    ANSWER=$(dig @$resolver google.com +short)
    
    echo "Response: $ANSWER"
    echo "Time: $TIME"
    echo ""
done > resolver_comparison.txt

cat resolver_comparison.txt
```


### ✅ Practice 7: Perform a Reverse DNS Lookup

```bash
cd ~/linux-course/part27

# Reverse lookup for common DNS servers
for ip in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do
    HOSTNAME=$(dig +short -x $ip)
    echo "$ip → $HOSTNAME"
done

# Check your own IP
MY_IP=$(hostname -I | awk '{print $1}')
echo "My IP: $MY_IP"
echo "Reverse: $(dig +short -x $MY_IP)"

# Check if reverse matches forward
echo "Forward of reverse:"
rev_name=$(dig +short -x $MY_IP)
if [ -n "$rev_name" ]; then
    dig +short $rev_name
fi
```


### ✅ Practice 8: Set Up nscd and Observe Caching

```bash
cd ~/linux-course/part27

# Install nscd if not present
which nscd || sudo apt install -y nscd

# Ensure it's running
sudo systemctl enable --now nscd

# Clear the cache first
sudo nscd -i hosts

# Time first lookup (cold cache)
echo "Cold cache:"
time getent hosts google.com

# Time second lookup (hot cache)
echo "Hot cache:"
time getent hosts google.com

# Compare
echo "Cache statistics:"
sudo nscd -g | head -20

# Check cache for hosts specifically
sudo nscd -g | grep -A 10 "hosts cache"
```


### ✅ Practice 9: Flush Caches and Verify

```bash
cd ~/linux-course/part27

# Flush nscd cache
sudo nscd -i hosts

# Flush systemd-resolved cache (if available)
sudo resolvectl flush-caches 2>/dev/null || echo "Not using systemd-resolved"

# Verify flush
echo "systemd-resolved stats (if available):"
resolvectl statistics 2>/dev/null | grep -i cache || echo "resolvectl not available"

echo "nscd stats after flush:"
sudo nscd -g | grep -i "cache\|hits\|misses" | head -10
```


### ✅ Practice 10: Debug Resolution with strace

```bash
cd ~/linux-course/part27

# Trace what happens when you resolve a hostname
strace -e openat,connect,sendto,recvfrom,read -o strace_resolve.log getent hosts google.com

# Analyze the trace
echo "=== Files opened during resolution ==="
grep "openat" strace_resolve.log | grep -E "(hosts|resolv|nsswitch|nss)" | head -10

echo ""
echo "=== DNS queries sent ==="
grep "sendto" strace_resolve.log | wc -l

echo ""
echo "=== DNS responses received ==="
grep "recvfrom" strace_resolve.log | wc -l

echo ""
echo "=== Full trace ==="
cat strace_resolve.log
```


### ✅ Practice 11: Test mDNS with Avahi

```bash
cd ~/linux-course/part27

# Check if Avahi is running
sudo systemctl status avahi-daemon 2>/dev/null || echo "Avahi not installed"

# If Avahi is running:
if systemctl is-active --quiet avahi-daemon 2>/dev/null; then
    # Discover services on the network
    timeout 5 avahi-browse -a -t -r 2>/dev/null || echo "No mDNS services found"
    
    # Check if this host is publishing its name
    avahi-resolve-hostname -4 $(hostname).local 2>/dev/null || echo "$(hostname).local not published"
fi

# Check nss-mdns installation
dpkg -l libnss-mdns 2>/dev/null || rpm -q libnss-mdns 2>/dev/null || echo "libnss-mdns not installed"
```


### ✅ Practice 12: Modify /etc/nsswitch.conf and Observe Behavior Change


### 📘 Level 3 Practices: Advanced Analysis and Integration

Perform a full domain DNS configuration analysis, set up a local Unbound cache, and build a comprehensive DNS health report.

### ✅ Practice 13: Analyze a Domain's Full DNS Configuration

```bash
cd ~/linux-course/part27

# Backup
sudo cp /etc/nsswitch.conf /etc/nsswitch.conf.backup

# Show current hosts line
echo "Current config:"
grep ^hosts /etc/nsswitch.conf

# Create a test entry in /etc/hosts
echo "192.168.100.100    testnss.local" | sudo tee -a /etc/hosts

# Verify it resolves via files
getent hosts testnss.local

# Now test what happens if we put dns before files
# (Don't actually change — just observe the behavior difference)
echo ""
echo "Key insight: getent hosts uses nsswitch order."
echo "dig bypasses nsswitch entirely."

# Clean up
sudo sed -i '/testnss.local/d' /etc/hosts
```


### ✅ Practice 13: Analyze a Domain's Full DNS Configuration

```bash
cd ~/linux-course/part27

DOMAIN="kernel.org"

echo "=== Full DNS Analysis: $DOMAIN ===" > dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- Authority (SOA) ---" >> dns_analysis.txt
dig +short SOA $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- Nameservers ---" >> dns_analysis.txt
dig +short NS $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- A Records ---" >> dns_analysis.txt
dig +short A $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- AAAA Records ---" >> dns_analysis.txt
dig +short AAAA $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- Mail Servers ---" >> dns_analysis.txt
dig +short MX $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- TXT Records ---" >> dns_analysis.txt
dig +short TXT $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- DNSSEC (if enabled) ---" >> dns_analysis.txt
dig +dnssec +short $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- Trace Path ---" >> dns_analysis.txt
dig +trace $DOMAIN +short >> dns_analysis.txt 2>/dev/null || true

echo "" >> dns_analysis.txt
echo "--- Nameserver Version Info ---" >> dns_analysis.txt
for ns in $(dig +short NS $DOMAIN); do
    echo "Querying $ns..." >> dns_analysis.txt
    dig @$ns chaos txt version.bind +short >> dns_analysis.txt 2>/dev/null
done

cat dns_analysis.txt
```


### ✅ Practice 14: Set Up a Local DNS Cache with Unbound

```bash
cd ~/linux-course/part27

# Install unbound
sudo apt install -y unbound 2>/dev/null || sudo dnf install -y unbound 2>/dev/null

# Create minimal config
sudo tee /etc/unbound/unbound.conf.d/local-cache.conf << 'EOF'
server:
    interface: 127.0.0.1
    port: 5353
    access-control: 127.0.0.0/8 allow
    verbosity: 1
    do-daemonize: yes
    prefetch: yes
    cache-min-ttl: 600
    cache-max-ttl: 86400
    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes
    hide-identity: yes
    hide-version: yes
EOF

# Start unbound
sudo systemctl restart unbound
sudo systemctl status unbound --no-pager | head -10

# Test: first query is cold (recursive, may be slow)
echo "First query (cold cache):"
time dig @127.0.0.1 -p 5353 google.com +short

# Second query (should be fast, from cache)
echo "Second query (hot cache):"
time dig @127.0.0.1 -p 5353 google.com +short

# Third query (cached, near-instant)
echo "Third query (cached):"
time dig @127.0.0.1 -p 5353 google.com +short
```


### ✅ Practice 15: Real-World Integration — DNS Health Report

```bash
cd ~/linux-course/part27

cat > dns_health_report.sh << 'EOF'
#!/bin/bash
set -euo pipefail

REPORT="dns_health_report.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

cat > "$REPORT" << HEADER
============================================
  DNS HEALTH REPORT
  Hostname: $HOSTNAME
  Date:     $TIMESTAMP
============================================

HEADER

# 1. System configuration
echo "[1] System DNS Configuration" >> "$REPORT"
echo "  resolv.conf:" >> "$REPORT"
ls -la /etc/resolv.conf >> "$REPORT" 2>&1
cat /etc/resolv.conf >> "$REPORT" 2>&1
echo "" >> "$REPORT"

echo "  nsswitch hosts line:" >> "$REPORT"
grep ^hosts /etc/nsswitch.conf >> "$REPORT"
echo "" >> "$REPORT"

# 2. DNS server availability
echo "[2] DNS Server Availability" >> "$REPORT"
for ns in $(grep nameserver /etc/resolv.conf | awk '{print $2}') 8.8.8.8 1.1.1.1; do
    if ping -c 1 -W 2 "$ns" > /dev/null 2>&1; then
        echo "  $ns: ONLINE (RTT: $(ping -c 1 -W 2 $ns 2>/dev/null | tail -1 | awk -F '/' '{print $5}')ms)" >> "$REPORT"
    else
        echo "  $ns: OFFLINE" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# 3. Test common domains
echo "[3] Domain Resolution Tests" >> "$REPORT"
for domain in google.com cloudflare.com kernel.org example.com; do
    IP=$(dig +short "$domain" | head -1)
    TIME=$( (time dig +short "$domain" > /dev/null) 2>&1 | grep real | awk '{print $2}')
    if [ -n "$IP" ]; then
        echo "  $domain -> $IP ($TIME)" >> "$REPORT"
    else
        echo "  $domain -> FAILED ($TIME)" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# 4. Cache status
echo "[4] DNS Cache Status" >> "$REPORT"
if command -v resolvectl &> /dev/null; then
    resolvectl statistics >> "$REPORT" 2>&1
elif command -v nscd &> /dev/null; then
    sudo nscd -g 2>/dev/null | grep -E "hosts|cache|hits|misses" >> "$REPORT"
else
    echo "  No caching daemon detected" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 5. Reverse DNS check
echo "[5] Reverse DNS Check" >> "$REPORT"
MY_IP=$(hostname -I | awk '{print $1}')
REV_NAME=$(dig +short -x "$MY_IP" 2>/dev/null)
if [ -n "$REV_NAME" ]; then
    echo "  $MY_IP -> $REV_NAME" >> "$REPORT"
else
    echo "  $MY_IP -> No PTR record" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 6. mDNS/LLMNR status
echo "[6] Local Name Resolution" >> "$REPORT"
if command -v resolvectl &> /dev/null; then
    resolvectl status | grep -E "LLMNR|mDNS|Protocols" >> "$REPORT"
elif command -v avahi-browse &> /dev/null; then
    echo "  Avahi daemon is available" >> "$REPORT"
else
    echo "  No local multicast resolution detected" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 7. DNSSEC validation
echo "[7] DNSSEC Validation Test" >> "$REPORT"
dig +dnssec +short com > /dev/null 2>&1 && echo "  DNSSEC: OK" >> "$REPORT" || echo "  DNSSEC: Not supported/Enabled" >> "$REPORT"
echo "" >> "$REPORT"

# 8. Performance summary
echo "[8] Resolution Performance" >> "$REPORT"
echo "  Average resolution time (3 queries to google.com):" >> "$REPORT"
for i in 1 2 3; do
    t=$( (time dig +short google.com > /dev/null) 2>&1 | grep real | awk '{print $2}')
    echo "    Attempt $i: $t" >> "$REPORT"
done
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF DNS HEALTH REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x dns_health_report.sh
./dns_health_report.sh
```





[← Previous](16-section-12-custom-hostname-resolution.md) | [↑ Index](index.md) | [Next →](18-deep-understanding-how-dns-resolution.md)
