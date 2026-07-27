## 15 Hands-On Practices

### Practice 1: Create and Explore PID Namespace

```bash
# Create an isolated PID namespace with /proc mounted
sudo unshare --pid --fork --mount-proc bash

# Inside the namespace:
ps aux
# Should show only 1-2 processes (bash + ps)

# Check PID 1
cat /proc/1/cmdline | tr '\0' ' '
# Should be "bash" or your entrypoint

# Check what PID you are on the host (from another terminal)
ps aux | grep "unshare"
# Note the host PID — different from namespace PID

# Verify namespace boundary
readlink /proc/self/ns/pid

# Cleanup
exit
```

✅ **Expected**: PID namespace shows only 2-3 processes. Host PID numbers differ.

### Practice 2: Multi-Level PID Namespace Tree

```bash
# Level 0: Create Level 1
sudo unshare --pid --fork --mount-proc bash
echo "Level 1 PID 1 = $$"

# Level 1: Create Level 2 (from inside Level 1)
unshare --pid --fork --mount-proc bash
echo "Level 2 PID 1 = $$"

# Check /proc/self/status in Level 2
grep NSpid /proc/self/status
# NSpid:  1  1     ← PID 1 in Level 2, PID 1 in Level 1
# (on host this is something like PID 5001)

# Check from Level 0 (another terminal)
lsns -t pid
# Should show 3 PID namespaces

# Cleanup both levels
exit; exit
```

✅ **Expected**: Three PID namespaces visible, with nested PID numbering.

### Practice 3: Network Namespace Isolation

```bash
# Create isolated network namespace
sudo ip netns add test_net

# Verify: no network connectivity inside
sudo ip netns exec test_net ping -c 1 8.8.8.8
# Should fail — no route

# Check interfaces
sudo ip netns exec test_net ip link show
# Only "lo" (loopback) — no eth0

# Bring up loopback
sudo ip netns exec test_net ip link set lo up
sudo ip netns exec test_net ping -c 1 127.0.0.1
# Should work

# Cleanup
sudo ip netns delete test_net
```

✅ **Expected**: Namespace has only loopback, no internet access.

### Practice 4: veth Pair Connectivity

```bash
# Create two namespaces connected by a veth pair
sudo ip netns add left
sudo ip netns add right

# Create veth pair
sudo ip link add veth-l type veth peer name veth-r

# Move ends to respective namespaces
sudo ip link set veth-l netns left
sudo ip link set veth-r netns right

# Configure left
sudo ip netns exec left ip addr add 10.0.0.1/24 dev veth-l
sudo ip netns exec left ip link set veth-l up
sudo ip netns exec left ip link set lo up

# Configure right
sudo ip netns exec right ip addr add 10.0.0.2/24 dev veth-r
sudo ip netns exec right ip link set veth-r up
sudo ip netns exec right ip link set lo up

# Test
sudo ip netns exec left ping -c 3 10.0.0.2
# Should succeed

# Cleanup
sudo ip netns delete left
sudo ip netns delete right
sudo ip link del veth-l 2>/dev/null
```

✅ **Expected**: Bidirectional ping between two isolated network namespaces.

### Practice 5: Bridge Networking with Three Namespaces

```bash
# Create bridge
sudo ip link add br0 type bridge
sudo ip addr add 10.0.0.1/24 dev br0
sudo ip link set br0 up

# Create 3 namespaces and connect to bridge
for i in a b c; do
    sudo ip netns add ns${i}
    sudo ip link add veth${i}-h type veth peer name veth${i}-c
    sudo ip link set veth${i}-c netns ns${i}
    sudo ip link set veth${i}-h master br0
    sudo ip link set veth${i}-h up
    sudo ip netns exec ns${i} ip addr add 10.0.0.${i%a+1}/24 dev veth${i}-c 2>/dev/null
    sudo ip netns exec ns${i} ip link set veth${i}-c up
    sudo ip netns exec ns${i} ip link set lo up
done

# Assign IPs: a=10.0.0.10, b=10.0.0.11, c=10.0.0.12
sudo ip netns exec a ip addr flush dev vetha-c
sudo ip netns exec a ip addr add 10.0.0.10/24 dev vetha-c
sudo ip netns exec b ip addr flush dev vethb-c
sudo ip netns exec b ip addr add 10.0.0.11/24 dev vethb-c
sudo ip netns exec c ip addr flush dev vethc-c
sudo ip netns exec c ip addr add 10.0.0.12/24 dev vethc-c

# Test: all three can communicate
sudo ip netns exec a ping -c 1 10.0.0.11
sudo ip netns exec b ping -c 1 10.0.0.12
sudo ip netns exec a ping -c 1 10.0.0.12

# Cleanup
for i in a b c; do sudo ip netns delete ns${i}; done
sudo ip link del br0
```

✅ **Expected**: Three namespaces communicate through the L2 bridge.

### Practice 6: Mount Namespace Isolation

```bash
# Create mount namespace
sudo unshare --mount bash

# Create a private directory with a secret file
mkdir -p /tmp/private
echo "secret-data" > /tmp/private/secret.txt

# Mount a tmpfs
mount -t tmpfs tmpfs /tmp/private

# Verify inside namespace
cat /tmp/private/secret.txt   # "secret-data"

# From host (another terminal):
cat /tmp/private/secret.txt
# Either "No such file" or shows old content (before tmpfs mount)
# The mount is invisible to host

# Create a read-only mount
mkdir /tmp/readonly
mount -t tmpfs -o ro tmpfs /tmp/readonly
echo "test" > /tmp/readonly/file 2>&1
# Read-only filesystem error

# Cleanup
exit
```

✅ **Expected**: Mount operations invisible from host.

### Practice 7: UTS Namespace Hostname Isolation

```bash
# Original hostname
hostname

# Create UTS namespace
sudo unshare --uts bash

# Change hostname
hostname container-test
hostname
# "container-test"

# From host (another terminal):
hostname
# Original hostname — unchanged

# Verify via syscall
cat /proc/sys/kernel/hostname
# "container-test" (inside namespace)

# Clean up
exit
hostname  # Back to original
```

✅ **Expected**: Hostname changes are contained within the UTS namespace.

### Practice 8: IPC Namespace Isolation

```bash
# Create IPC namespace
sudo unshare --ipc bash

# Create IPC objects
ipcmk -M 1024      # Shared memory
ipcmk -S 1         # Semaphore
ipcmk -Q           # Message queue

# List them
ipcs

# From host (another terminal):
ipcs
# These objects should NOT appear — IPC namespace isolates them

# Cleanup
ipcrm --all=shm
ipcrm --all=msg
ipcrm --all=sem
exit
```

✅ **Expected**: IPC objects are invisible across namespace boundaries.

### Practice 9: User Namespace Rootless Container

```bash
# Create a user namespace with PID and mount
unshare --user --pid --mount --fork --map-root-user bash

# We are root inside
id
# uid=0(root) gid=0(root) groups=0(root)

# Check mapped UIDs
cat /proc/self/uid_map
#          0     100000      65536

# Verify: on host we're still unprivileged
# From another terminal:
ps aux | grep "unshare"
# Shows original user (e.g., tim), NOT root

# Mount proc in PID namespace
mount -t proc proc /proc
ps aux
# Shows only our processes

# Try to access host files (should fail)
ls /root/
# Permission denied — we're not real root

# Exit user namespace
exit
```

✅ **Expected**: UID 0 inside namespace, unprivileged outside.

### Practice 10: cgroup Namespace and Resource Limits

```bash
# Create a cgroup with memory limit
sudo mkdir -p /sys/fs/cgroup/limited_workload

# Set 50MB memory limit
echo 52428800 | sudo tee /sys/fs/cgroup/limited_workload/memory.max

# Set PID limit
echo 20 | sudo tee /sys/fs/cgroup/limited_workload/pids.max

# Run a process inside this cgroup
echo $$ | sudo tee /sys/fs/cgroup/limited_workload/cgroup.procs

# Verify limits
cat /sys/fs/cgroup/limited_workload/memory.max
# 52428800
cat /sys/fs/cgroup/limited_workload/pids.max
# 20

# Check memory pressure events
cat /sys/fs/cgroup/limited_workload/memory.events
# low 0
# high 0
# max 0

# Cleanup
echo $$ | sudo tee /sys/fs/cgroup/cgroup.procs
sudo rmdir /sys/fs/cgroup/limited_workload
```

✅ **Expected**: cgroup limits are enforced on the process.

### Practice 11: nsenter into Container Namespace

```bash
# Start a container
docker run -d --name ns_demo nginx:alpine
sleep 2

# Get container PID
PID=$(docker inspect --format '{{.State.Pid}}' ns_demo)
echo "Container PID on host: $PID"

# View container namespaces
echo "=== Namespaces ==="
for ns in pid net mnt uts ipc; do
    echo "$ns: $(readlink /proc/$PID/ns/$ns)"
done

# Enter the container's PID namespace
sudo nsenter -t $PID -p -- ps aux
# Shows processes INSIDE the container

# Enter the container's network namespace
sudo nsenter -t $PID -n -- ip addr
# Shows container's network interfaces

# Enter the container's mount namespace and inspect filesystem
sudo nsenter -t $PID -m -- ls /usr/share/nginx/html/

# Cleanup
docker rm -f ns_demo
```

✅ **Expected**: Host tools can inspect container internals via nsenter.

### Practice 12: Build a Container from Scratch

```bash
# Create a minimal rootfs
mkdir -p /tmp/mycontainer/{bin,lib,lib64,etc,proc,sys,dev,tmp}

# Copy essential binaries (static)
cp /bin/busybox /tmp/mycontainer/bin/
# Or download: wget https://busybox.net/downloads/binaries/...

# Create minimal /etc files
echo "root:x:0:0:root:/root:/bin/sh" > /tmp/mycontainer/etc/passwd
echo "root:x:0:" > /tmp/mycontainer/etc/group
echo "mycontainer" > /tmp/mycontainer/etc/hostname

# Create the container with namespaces
sudo unshare --pid --net --mount --uts --ipc --fork \
    bash -c "
        # Set hostname
        hostname mycontainer

        # Mount /proc
        mount -t proc proc /tmp/mycontainer/proc

        # Pivot root
        cd /tmp/mycontainer
        mkdir -p old_root
        mount --bind . .
        pivot_root . old_root

        # Unmount old root
        umount -l /old_root 2>/dev/null

        # Verify
        echo '=== Inside Container ==='
        hostname
        ps aux
        ls /
        id

        # Cleanup
        umount /proc 2>/dev/null
    "

# Cleanup
sudo rm -rf /tmp/mycontainer
```

✅ **Expected**: You've built a working container from namespaces alone.

### Practice 13: Network Namespace with NAT

```bash
# Create namespace and connect to host
sudo ip netns add nat_ns
sudo ip link add veth-host type veth peer name veth-ns
sudo ip link set veth-ns netns nat_ns
sudo ip addr add 10.100.0.1/24 dev veth-host
sudo ip link set veth-host up
sudo ip netns exec nat_ns ip addr add 10.100.0.2/24 dev veth-ns
sudo ip netns exec nat_ns ip link set veth-ns up
sudo ip netns exec nat_ns ip link set lo up
sudo ip netns exec nat_ns ip route add default via 10.100.0.1

# Enable forwarding and NAT
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i veth-host -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o veth-host -m state --state RELATED,ESTABLISHED -j ACCEPT

# Test internet access from namespace
sudo ip netns exec nat_ns ping -c 2 8.8.8.8

# Cleanup
sudo ip netns delete nat_ns
sudo ip link del veth-host
sudo iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
sudo iptables -D FORWARD -i veth-host -o eth0 -j ACCEPT
sudo iptables -D FORWARD -i eth0 -o veth-host -m state --state RELATED,ESTABLISHED -j ACCEPT
```

✅ **Expected**: Namespace reaches internet through host NAT.

### Practice 14: Inspect All Docker Container Namespaces

```bash
# Create several containers
docker run -d --name web nginx:alpine
docker run -d --name db postgres:alpine

# Get their PIDs
WEB_PID=$(docker inspect --format '{{.State.Pid}}' web)
DB_PID=$(docker inspect --format '{{.State.Pid}}' db)

# Compare namespaces
echo "=== Web Container ==="
ls -la /proc/$WEB_PID/ns/

echo ""
echo "=== DB Container ==="
ls -la /proc/$DB_PID/ns/

# Verify they share NO namespaces (all inodes differ)
echo ""
echo "=== Namespace Comparison ==="
for ns in pid net mnt uts ipc user cgroup; do
    WEB_NS=$(readlink /proc/$WEB_PID/ns/$ns)
    DB_NS=$(readlink /proc/$DB_PID/ns/$ns)
    if [ "$WEB_NS" = "$DB_NS" ]; then
        echo "$ns: SHARED ($WEB_NS)"
    else
        echo "$ns: ISOLATED"
    fi
done

# Cleanup
docker rm -f web db
```

✅ **Expected**: All namespaces show "ISOLATED" — complete container isolation.

### Practice 15: Comprehensive Namespace Dashboard Script

```bash
#!/bin/bash
# ns_dashboard.sh — Display all namespace information for a process

PID=${1:-$$}

echo "═══════════════════════════════════════════════════════════"
echo "  NAMESPACE DASHBOARD for PID $PID"
echo "═══════════════════════════════════════════════════════════"

echo ""
echo "Process Info:"
ps -p $PID -o pid,ppid,user,comm,args --no-headers 2>/dev/null || echo "Process not found"

echo ""
echo "Namespaces:"
for ns in pid net mnt uts ipc user cgroup time; do
    LINK=$(readlink /proc/$PID/ns/$ns 2>/dev/null || echo "N/A")
    INODE=$(echo "$LINK" | grep -oP '\d+')
    echo "  $ns: $LINK"
done

echo ""
echo "Caps (hex):"
grep Cap /proc/$PID/status 2>/dev/null

echo ""
echo "Mount Points (top 10):"
head -10 /proc/$PID/mountinfo 2>/dev/null || echo "N/A"

echo ""
echo "Network Interfaces:"
nsenter -t $PID -n ip addr 2>/dev/null || echo "N/A"

echo ""
echo "Cgroup:"
cat /proc/$PID/cgroup 2>/dev/null || echo "N/A"

echo ""
echo "Ulimits:"
grep -E "Max|" /proc/$PID/limits 2>/dev/null

echo "═══════════════════════════════════════════════════════════"
```

```bash
chmod +x ns_dashboard.sh

# Dashboard for current process
./ns_dashboard.sh

# Dashboard for a Docker container
CONTAINER_PID=$(docker inspect --format '{{.State.Pid}}' web)
sudo ./ns_dashboard.sh $CONTAINER_PID
```

✅ **Expected**: Complete namespace overview for any process or container.

---



---

[← Previous](10-9-namespace-security.md) | [↑ Index](index.md) | [Next →](12-deep-understanding.md)
