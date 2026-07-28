## 💻 PRACTICE SECTION — 15 Hands-On Exercises


### 📘 Level 1 Practices: NFS Concepts and Installation

Install the NFS server, verify daemons, check RPC registrations, and export your first directory.

### ✅ Practice 1: Install and Verify NFS Server

```bash
mkdir -p ~/linux-course/part28
cd ~/linux-course/part28

# Install NFS server
sudo apt update && sudo apt install -y nfs-kernel-server nfs-common

# Verify the daemons are running
sudo systemctl status nfs-server --no-pager | head -20

# Check rpcbind registrations
rpcinfo -p localhost

# Identify which programs are registered:
#   100000 = portmapper
#   100003 = nfsd
#   100005 = mountd
#   100024 = statd

# Save output
rpcinfo -p localhost > rpcinfo_output.txt
cat rpcinfo_output.txt

echo "Practice 1 complete — NFS server is ready"
```


### ✅ Practice 2: Export a Directory via NFS


### 📘 Level 2 Practices: Client Setup, Autofs, Security, and Troubleshooting

Mount NFS shares with various options, configure autofs for on-demand mounting, apply security settings including root_squash and Kerberos, and practice troubleshooting with rpcinfo and showmount.

```bash
cd ~/linux-course/part28

# Create a directory to export
sudo mkdir -p /export/nfs/data
sudo chmod 777 /export/nfs/data

# Add an export entry
echo "/export/nfs/data *(rw,sync,no_subtree_check,no_root_squash)" | \
  sudo tee -a /etc/exports

# Apply exports
sudo exportfs -ra

# Verify export
sudo exportfs -v

# Check from client perspective (locally)
showmount -e localhost

echo "Practice 2 complete — directory exported"
```


### ✅ Practice 3: Mount NFS Share Locally (Loopback)

```bash
cd ~/linux-course/part28

# Create mount point
sudo mkdir -p /mnt/nfs_test

# Mount the local export (loopback NFS)
sudo mount -t nfs4 localhost:/export/nfs/data /mnt/nfs_test

# Verify mount
mount | grep nfs_test
df -h /mnt/nfs_test

# Test write access
echo "Hello from NFS client at $(date)" | sudo tee /mnt/nfs_test/testfile.txt
cat /mnt/nfs_test/testfile.txt

# Verify the file exists on the server side
ls -la /export/nfs/data/

# Unmount
sudo umount /mnt/nfs_test

echo "Practice 3 complete — loopback NFS mount works"
```


### ✅ Practice 4: NFS Mount Options Deep Dive

```bash
cd ~/linux-course/part28

# Mount with different options and compare
for opts in "hard,noatime" "soft,noatime,timeo=10,retrans=3" "hard,noatime,rsize=32768,wsize=32768"; do
    echo "=== Testing options: $opts ==="
    sudo mount -t nfs4 -o "$opts" localhost:/export/nfs/data /mnt/nfs_test

    # Run a quick benchmark
    dd if=/dev/zero of=/mnt/nfs_test/bench bs=1M count=100 2>&1 | tail -1
    dd of=/dev/null if=/mnt/nfs_test/bench bs=1M count=100 2>&1 | tail -1

    sudo umount /mnt/nfs_test
done

# Test hard mount behavior (must be run as root)
# Open a second terminal and run:
# sudo umount -f /mnt/nfs_test
# Meanwhile, in the first terminal:
sudo mount -t nfs4 -o hard localhost:/export/nfs/data /mnt/nfs_test
# Try: cat /mnt/nfs_test/testfile.txt (will block if server unavailable)

sudo umount /mnt/nfs_test

echo "Practice 4 complete — mount options explored"
```


### ✅ Practice 5: /etc/fstab NFS Mount

```bash
cd ~/linux-course/part28

# Create mount point
sudo mkdir -p /mnt/nfs_auto

# Add to /etc/fstab
echo "localhost:/export/nfs/data /mnt/nfs_auto nfs4 rw,hard,intr,noatime,_netdev 0 0" | \
  sudo tee -a /etc/fstab

# Mount all fstab entries (then unmount)
sudo mount /mnt/nfs_auto
mount | grep nfs_auto
sudo umount /mnt/nfs_auto

# Remove the fstab entry
# (backup fstab first)
sudo cp /etc/fstab /etc/fstab.backup
sudo sed -i '/nfs_auto/d' /etc/fstab

echo "Practice 5 complete — fstab NFS mount configured"
```


### ✅ Practice 6: Create a Systemd Mount Unit for NFS

```bash
cd ~/linux-course/part28

# Create a systemd mount unit
sudo tee /etc/systemd/system/mnt-nfs_systemd.mount << 'EOF'
[Unit]
Description=NFS mount for systemd practice
After=network-online.target
Wants=network-online.target

[Mount]
What=localhost:/export/nfs/data
Where=/mnt/nfs_systemd
Type=nfs4
Options=rw,hard,noatime,vers=4.2

[Install]
WantedBy=multi-user.target
EOF

sudo mkdir -p /mnt/nfs_systemd
sudo systemctl daemon-reload

# Start and verify
sudo systemctl start mnt-nfs_systemd.mount
sudo systemctl status mnt-nfs_systemd.mount --no-pager | head -15
mount | grep nfs_systemd

# Test access
echo "Systemd mount unit test" | sudo tee /mnt/nfs_systemd/systemd_test.txt

# Stop and disable
sudo systemctl stop mnt-nfs_systemd.mount
sudo systemctl disable mnt-nfs_systemd.mount
sudo rm /etc/systemd/system/mnt-nfs_systemd.mount
sudo systemctl daemon-reload

echo "Practice 6 complete — systemd mount unit created"
```


### ✅ Practice 7: Configure Autofs for NFS

```bash
cd ~/linux-course/part28

# Install autofs
sudo apt install -y autofs

# Create an indirect autofs map
sudo tee /etc/auto.nfs << 'EOF'
# Auto-mount map for NFS shares
data    -rw,hard,intr,noatime    localhost:/export/nfs/data
EOF

# Add to auto.master
echo "/nfs  /etc/auto.nfs  --timeout=60 --ghost" | sudo tee -a /etc/auto.master

# Restart autofs
sudo systemctl restart autofs

# Test: access the mount point
ls -la /nfs/data

# Verify it's actually mounted
mount | grep /nfs/data
df -h /nfs/data

# Test auto-unmount (wait 60 seconds or force)
sudo systemctl status autofs --no-pager | head -10

# Show autofs statistics
automount --status 2>&1 | head -20

echo "Practice 7 complete — autofs configured"
```


### ✅ Practice 8: Wildcard Autofs Map

```bash
cd ~/linux-course/part28

# Create additional export for wildcard test
sudo mkdir -p /export/nfs/docs
sudo chmod 777 /export/nfs/docs
echo "/export/nfs/docs *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra

# Create a direct map with wildcard
sudo tee /etc/auto.nfs_direct << 'EOF'
# Wildcard indirect map — & substitutes the key
*       -rw,hard,intr,noatime   localhost:/export/nfs/&
EOF

# Add to auto.master
echo "/nfswild  /etc/auto.nfs_direct  --timeout=60" | sudo tee -a /etc/auto.master

sudo systemctl restart autofs

# Test wildcard: accessing /nfswild/data should mount /export/nfs/data
ls -la /nfswild/data
mount | grep nfswild

# Test wildcard: accessing /nfswild/docs should mount /export/nfs/docs
ls -la /nfswild/docs
mount | grep nfswild

echo "Practice 8 complete — wildcard autofs working"
```


### ✅ Practice 9: Export Security — root_squash

```bash
cd ~/linux-course/part28

# Create a separate export with root_squash (default behavior)
sudo mkdir -p /export/nfs/squashed
sudo chmod 777 /export/nfs/squashed

echo "/export/nfs/squashed *(rw,sync,no_subtree_check,root_squash)" | \
  sudo tee -a /etc/exports

# Create an export WITHOUT root_squash
sudo mkdir -p /export/nfs/nosquash
sudo chmod 777 /export/nfs/nosquash

echo "/export/nfs/nosquash *(rw,sync,no_subtree_check,no_root_squash)" | \
  sudo tee -a /etc/exports

sudo exportfs -ra

# Mount both and test root behavior
sudo mkdir -p /mnt/squashed /mnt/nosquash

sudo mount -t nfs4 localhost:/export/nfs/squashed /mnt/squashed
sudo mount -t nfs4 localhost:/export/nfs/nosquash /mnt/nosquash

# As root, create a file owned by root
sudo touch /mnt/squashed/rootfile.txt
sudo touch /mnt/nosquash/rootfile.txt

# Check ownership
echo "Squashed (root_squash) — root file owned by:"
ls -la /mnt/squashed/rootfile.txt

echo "No-squash (no_root_squash) — root file owned by:"
ls -la /mnt/nosquash/rootfile.txt

# The difference: squashed file should be owned by nobody/nfsnobody
# nosquash file should be owned by root

sudo umount /mnt/squashed /mnt/nosquash

echo "Practice 9 complete — root_squash behavior observed"
```


### ✅ Practice 10: Kerberos Preparation (Keytab Setup)

```bash
cd ~/linux-course/part28

# Install Kerberos client
sudo apt install -y krb5-user 2>&1 | tail -5 || echo "Kerberos installed or already present"

# Check if a KDC is running locally
sudo systemctl status krb5-kdc --no-pager 2>/dev/null | head -5 || echo "No KDC — will simulate"

# Create a Kerberos configuration for demo
sudo tee /etc/krb5.conf << 'EOF'
[libdefaults]
  default_realm = EXAMPLE.COM
  dns_lookup_realm = false
  dns_lookup_kdc = false
[realms]
  EXAMPLE.COM = {
    kdc = localhost
    admin_server = localhost
  }
EOF

# Test: export with Kerberos option in /etc/exports
echo "# Simulated Kerberos export (requires KDC for real use)" | \
  sudo tee -a /etc/exports
echo "# /export/secure *(rw,sec=krb5p)" | sudo tee -a /etc/exports

# Show the sec= option in the exports file
grep -n "sec=krb5" /etc/exports

# Re-export (ignores comments)
sudo exportfs -ra

echo "Practice 10 complete — Kerberos config structure in place"
echo "Real Kerberos NFS requires: KDC, service principal, keytab"
```


### ✅ Practice 11: Troubleshoot with rpcinfo and showmount


### 📘 Level 3 Practices: Performance Tuning and Protocol Internals

Benchmark NFS performance with dd and nfsstat, tune rsize/wsize for optimal throughput, test locking and delegation, and build a multi-client NFS deployment with autofs and security.

```bash
cd ~/linux-course/part28

# Create a troubleshooting test

# 1. Health check script
cat > nfs_health_check.sh << 'EOF'
#!/bin/bash
echo "=== NFS Health Check ==="
echo "Date: $(date)"
echo ""

# Check rpcbind
echo "1. rpcbind status:"
if rpcinfo -p localhost > /dev/null 2>&1; then
    echo "   ✓ rpcbind is responding"
    rpcinfo -p localhost | grep -E "nfs|mount|nlock|statd" | \
      awk '{printf "   %s (v%s) on port %s\n", $4, $3, $5}'
else
    echo "   ✗ rpcbind is NOT responding"
fi
echo ""

# Check exports
echo "2. Exported directories:"
showmount -e localhost 2>/dev/null | tail -n +2 | \
  while read line; do echo "   $line"; done
echo ""

# Check mount
echo "3. Active NFS mounts:"
mount -t nfs4,nfs 2>/dev/null | head -20
echo ""

# Check nfsd threads
echo "4. NFS server threads:"
cat /proc/fs/nfsd/threads 2>/dev/null || echo "   Not available"
echo ""

# Check NFS version
echo "5. NFS kernel module info:"
modinfo nfsd 2>/dev/null | grep -E "version|description" | head -3
echo ""

echo "=== End of Health Check ==="
EOF

chmod +x nfs_health_check.sh
./nfs_health_check.sh

echo "Practice 11 complete — troubleshooting tools explored"
```


### ✅ Practice 12: Performance Benchmarking with dd and nfsstat

```bash
cd ~/linux-course/part28

# Mount with default options
sudo mount -t nfs4 localhost:/export/nfs/data /mnt/nfs_test

# Collect baseline statistics
nfsstat -c > nfsstat_before.txt
cat nfsstat_before.txt

# Run a write benchmark
echo "=== Write Benchmark ==="
dd if=/dev/zero of=/mnt/nfs_test/perf_test bs=1M count=500 2>&1

# Run a read benchmark
echo "=== Read Benchmark ==="
echo 3 | sudo tee /proc/sys/vm/drop_caches  # Clear cache
dd if=/mnt/nfs_test/perf_test of=/dev/null bs=1M count=500 2>&1

# Check statistics after
nfsstat -c > nfsstat_after.txt
diff nfsstat_before.txt nfsstat_after.txt || true

# Check mountstats for detailed info
grep -A30 "/mnt/nfs_test" /proc/self/mountstats | head -30

# Clean up
sudo rm /mnt/nfs_test/perf_test
sudo umount /mnt/nfs_test

echo "Practice 12 complete — performance baseline captured"
```


### ✅ Practice 13: Tune rsize/wsize for Performance

```bash
cd ~/linux-course/part28

# Test different rsize/wsize values
for size in 16384 32768 65536 131072 262144 524288 1048576; do
    sudo mount -t nfs4 -o rsize=$size,wsize=$size,noatime \
      localhost:/export/nfs/data /mnt/nfs_test

    echo "Testing rsize/wsize = $size bytes:"
    echo -n "  Write: "
    dd if=/dev/zero of=/mnt/nfs_test/bench bs=$size count=200 2>&1 | \
      grep -o "[0-9.]\+ MB/s" || \
      dd if=/dev/zero of=/mnt/nfs_test/bench bs=$size count=200 2>&1 | \
      tail -1 | awk '{print $NF}'

    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    echo -n "  Read:  "
    dd if=/mnt/nfs_test/bench of=/dev/null bs=$size count=200 2>&1 | \
      grep -o "[0-9.]\+ MB/s" || \
      dd if=/mnt/nfs_test/bench of=/dev/null bs=$size count=200 2>&1 | \
      tail -1 | awk '{print $NF}'

    sudo rm /mnt/nfs_test/bench
    sudo umount /mnt/nfs_test
done

echo "Practice 13 complete — optimal buffer size determined"
```


### ✅ Practice 14: NFS Locking and Delegation Test

```bash
cd ~/linux-course/part28

# Mount for lock testing
sudo mount -t nfs4 localhost:/export/nfs/data /mnt/nfs_test

# Create a test file
echo "lock test content" | sudo tee /mnt/nfs_test/lockme.txt

# Test 1: flock exclusive lock
echo "=== Test 1: flock exclusive lock ==="
flock -x /mnt/nfs_test/lockme.txt -c "echo '  Acquired exclusive lock at $(date)'" 2>&1 || \
  echo "  flock may not be available, trying fallback"

# Test 2: Multiple concurrent locks (run in background)
echo "=== Test 2: Concurrent lock test ==="

# Create a lock helper script
cat > lock_test.sh << 'EOF'
#!/bin/bash
FILE="/mnt/nfs_test/lockme.txt"
echo "  Process $$ attempting lock on $FILE"
flock -x "$FILE" -c "
  echo \"  Process $$ acquired lock at \$(date)\"
  sleep 2
  echo \"  Process $$ releasing lock at \$(date)\"
" 2>&1
EOF

chmod +x lock_test.sh

# Run two lock processes in parallel
./lock_test.sh &
PID1=$!
./lock_test.sh &
PID2=$!
wait $PID1 $PID2

echo "=== Lock test complete ==="

# Check delegation statistics
echo "=== Delegation stats ==="
grep -E "deleg|open|close" /proc/self/mountstats | \
  grep -A5 "/mnt/nfs_test" || \
  echo "  Delegation stats available in mountstats"

sudo umount /mnt/nfs_test

echo "Practice 14 complete — NFS locking fundamentals explored"
```


### ✅ Practice 15: Real-World Integration — Multi-Client NFS with Autofs and Security

```bash
cd ~/linux-course/part28

# This practice simulates a real-world scenario:
#   - NFS server exports multiple directories
#   - Autofs mounts on demand
#   - Security restrictions are applied
#   - Performance is benchmarked
#   - Troubleshooting is demonstrated

echo "=== Real-World NFS Integration ==="

# ---- STEP 1: Server Setup ----
echo "[1/7] Setting up server exports..."

# Create structured exports
sudo mkdir -p /export/{homes,projects,public,backups}
sudo chmod 755 /export/homes /export/projects /export/backups
sudo chmod 777 /export/public

# Create test content
echo "Welcome to the public share" | sudo tee /export/public/README.txt
echo "Project Alpha data" | sudo tee /export/projects/alpha.txt
echo "Backup placeholder" | sudo tee /export/backups/daily.tar.gz

# Write comprehensive /etc/exports
sudo tee /etc/exports << 'EOF'
# Real-world NFS exports configuration
# Public read-only
/export/public          *(ro,all_squash,no_subtree_check)

# Internal projects (restricted subnet)
/export/projects        10.0.0.0/24(rw,root_squash,no_subtree_check)
/export/projects        192.168.1.0/24(ro,root_squash,no_subtree_check)

# Home directories (per-host access simulated)
/export/homes           127.0.0.1(rw,root_squash,no_subtree_check)

# Backups (write-only for backup server)
/export/backups         127.0.0.1(rw,root_squash,no_subtree_check)
EOF

sudo exportfs -ra
echo "  Exports active:"
showmount -e localhost

# ---- STEP 2: Autofs Configuration ----
echo "[2/7] Configuring autofs..."

# Create autofs maps
sudo tee /etc/auto.nfs_prod << 'EOF'
# Production NFS autofs map
public      -ro,hard,intr,noatime        localhost:/export/public
projects    -rw,hard,intr,noatime        localhost:/export/projects
homes       -rw,hard,intr,noatime        localhost:/export/homes
backups     -rw,hard,intr,noatime        localhost:/export/backups
EOF

# Add to auto.master (avoid duplicate entries)
grep -q "auto.nfs_prod" /etc/auto.master || \
  echo "/prod  /etc/auto.nfs_prod  --timeout=120 --ghost" | sudo tee -a /etc/auto.master

sudo systemctl restart autofs
echo "  Autofs restarted. Mount points: /prod/{public,projects,homes,backups}"

# ---- STEP 3: Test Access ----
echo "[3/7] Testing access to all exports..."

for share in public projects homes backups; do
    echo -n "  Accessing /prod/$share ... "
    timeout 5 ls /prod/$share/ > /dev/null 2>&1 && \
      echo "OK ($(ls /prod/$share/ | wc -l) items)" || \
      echo "FAIL"
done

# ---- STEP 4: Write Test ----
echo "[4/7] Testing read/write permissions..."

# Public should be read-only
echo -n "  Write to public (expect failure): "
echo "test" > /prod/public/test.txt 2>&1 && echo "FAIL (should be ro)" || echo "OK (read-only)"

# Projects should be writable
echo -n "  Write to projects: "
echo "test" | sudo tee /prod/projects/test.txt > /dev/null 2>&1 && \
  echo "OK" || echo "FAIL"

# ---- STEP 5: root_squash Verification ----
echo "[5/7] Verifying root_squash..."

sudo touch /prod/projects/root_test.txt
OWNER=$(ls -la /prod/projects/root_test.txt | awk '{print $3}')
if [ "$OWNER" = "nobody" ] || [ "$OWNER" = "nfsnobody" ]; then
    echo "  ✓ root_squash active: root file owned by $OWNER"
else
    echo "  Note: root file owned by $OWNER (root_squash may not apply locally)"
fi

# ---- STEP 6: Performance Test ----
echo "[6/7] Running performance benchmark..."

sudo mount -t nfs4 -o rw,hard,noatime localhost:/export/projects /mnt/nfs_test

echo -n "  Write speed: "
dd if=/dev/zero of=/mnt/nfs_test/perf bs=1M count=100 2>&1 | tail -1 | awk '{print $NF}'

echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

echo -n "  Read speed:  "
dd if=/mnt/nfs_test/perf of=/dev/null bs=1M count=100 2>&1 | tail -1 | awk '{print $NF}'

sudo rm /mnt/nfs_test/perf
sudo umount /mnt/nfs_test

# ---- STEP 7: Troubleshooting & Verification ----
echo "[7/7] Final verification..."

# Check all mounts
echo "  Active NFS mounts:"
mount -t nfs4,nfs 2>/dev/null | head -10

# Check exports
echo "  Current exports:"
sudo exportfs -v | head -20

# RPC health
echo "  RPC services:"
rpcinfo -p localhost 2>/dev/null | grep -E "nfs|mount|nlock|statd" | \
  awk '{printf "    %s (v%s)\n", $4, $3}'

echo ""
echo "=== Real-World Integration Complete ==="
echo "Scenario: Multi-export NFS server with autofs,"
echo "  read-only public share, restricted projects,"
echo "  root_squash security, and performance validation."
```





[← Previous](15-section-11-locking-in-nfs.md) | [↑ Index](index.md) | [Next →](17-deep-understanding-how-nfs-really.md)
