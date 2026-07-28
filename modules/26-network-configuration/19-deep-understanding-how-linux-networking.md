## 🧠 Deep Understanding — How Linux Networking Really Works

### The Network Stack (OSI Model in Linux)

Linux implements the network stack in kernel space. Here is how the layers map:

```
Layer 7 (Application)     ─┐
    HTTP, SSH, DNS         │  User space
Layer 4 (Transport)        │  (socket interface)
    TCP, UDP               │
                           │
Layer 3 (Network)         ─┤  Kernel space
    IP, ICMP, ARP          │  Network stack
                           │
Layer 2 (Data Link)       ─┤
    Ethernet, Bridge       │  Device drivers
                           │
Layer 1 (Physical)        ─┤  Hardware
    Cable, Radio           │
```

### How a Packet Flows: Sending

```
Application: send(sockfd, "Hello", 5, 0);
    ↓
1. User space → Kernel boundary (syscall)
    ↓
2. Socket layer — buffers the data, determines protocol (TCP/UDP)
    ↓
3. TCP layer — segments the data, adds sequence numbers, computes checksum
    ↓
4. IP layer — wraps in IP packet, determines routing (fib_lookup → routing table)
    ↓
5. Neighbor layer — resolves next-hop MAC via ARP (or finds cached entry)
    ↓
6. Device driver — enqueues packet on TX ring buffer
    ↓
7. NIC — transmits bits on the wire (DMA from memory to cable)
    ↓
8. Interrupt fires when transmission completes → driver frees the buffer
```

### How a Packet Flows: Receiving

```
NIC receives bits on the wire
    ↓
1. DMA — NIC writes packet data directly to memory (no CPU involvement)
    ↓
2. Interrupt — NIC raises IRQ → kernel runs interrupt handler
    ↓
3. NAPI — modern drivers use polling to avoid interrupt storm
    ↓
4. GRO — Generic Receive Offload merges smaller packets
    ↓
5. Netfilter — hooks for iptables/nftables
    ↓
6. IP layer — reassembles fragments, routes lookup (is it for us? forward?)
    ↓
7. TCP layer — checksums, orders segments (if the local socket)
    ↓
8. Socket receive queue — data is available for recv()
    ↓
9. Application reads data via syscall (recvfrom, read)
```

### Netlink Sockets — How `ip` Talks to the Kernel

The `ip` command (and `ss`, `bridge`, `devlink`) communicates with the kernel via **Netlink sockets**. Netlink is a socket-based IPC mechanism specifically for kernel-to-user and user-to-kernel networking control.

```bash
# Netlink socket types used by iproute2:
# NETLINK_ROUTE — routing, links, addresses, neighbors
# NETLINK_SOCK_DIAG — socket diagnostics (ss)
# NETLINK_NEIGHBOR — neighbor discovery
# NETLINK_FIB_LOOKUP — forwarding information base

# See Netlink sockets on your system
ss -f netlink

# strace the ip command to see Netlink in action
strace -e socket,sendmsg,recvmsg ip addr show 2>&1 | head -20
```

Output of strace:
```
socket(AF_NETLINK, SOCK_RAW|SOCK_CLOEXEC, NETLINK_ROUTE) = 3
sendmsg(3, {msg_name={...}, msg_iov=[...]}, 0) = 40
recvmsg(3, {msg_name={...}, msg_iov=[...]}, 0) = 4096
```

This is why `ip` is more powerful than `ifconfig` — Netlink supports adding new message types without changing the kernel ABI, while `ioctl` requires new ioctl numbers for every feature.

### The Role of udev in Interface Naming

When the kernel discovers a new network device, it:

1. Creates a `net` device in sysfs (`/sys/class/net/<name>/`)
2. Sends a `uevent` to udev
3. udev looks at its rules in `/lib/udev/rules.d/`
4. Rules check for `ID_NET_NAME_ONBOARD`, `ID_NET_NAME_SLOT`, `ID_NET_NAME_MAC`
5. udev renames the interface using `ip link set dev <old> name <new>`
6. The new name is assigned based on the best available identifier

```bash
# Trace udev events for a new device
sudo udevadm monitor --property | grep -E "INTERFACE|ACTION|ID_NET"

# Simulate a new device event
sudo udevadm trigger --verbose --subsystem-match=net
```

### Network Namespaces — Lightweight Virtual Networking

A network namespace is a separate copy of the network stack with its own interfaces, routes, firewall rules, and sockets. Containers use this heavily.

```bash
# Create a network namespace
sudo ip netns add blue
sudo ip netns add red

# Create a veth pair connecting them
sudo ip link add veth-blue type veth peer name veth-red

# Move each end into its namespace
sudo ip link set veth-blue netns blue
sudo ip link set veth-red netns red

# Configure in the blue namespace
sudo ip netns exec blue ip addr add 10.0.0.1/24 dev veth-blue
sudo ip netns exec blue ip link set veth-blue up
sudo ip netns exec blue ip link set lo up

# Configure in the red namespace
sudo ip netns exec red ip addr add 10.0.0.2/24 dev veth-red
sudo ip netns exec red ip link set veth-red up
sudo ip netns exec red ip link set lo up

# Ping from blue to red
sudo ip netns exec blue ping -c 2 10.0.0.2

# Check processes in each namespace
sudo ip netns exec blue ps aux

# Each namespace has its own:
# - Interfaces (lo is separate)
# - Routing table
# - ARP table
# - iptables rules
# - /proc/net/*
# - Sockets (port 80 can be used in both)
```

```bash
# List all namespaces
ip netns list

# Show routes in a namespace
sudo ip netns exec blue ip route

# Run a shell in a namespace
sudo ip netns exec blue bash
# Now you're in the "blue" network stack!
```

### The Socket Buffer (sk_buff)

Every packet in the kernel travels inside an `sk_buff` structure. This is the fundamental data structure of the network stack:

```
┌──────────────────────────────────┐
│  sk_buff                         │
├──────────────────────────────────┤
│  dev         ← incoming/outgoing │
│  sk          ← owning socket     │
│  protocol   ← EtherType          │
│  priority   ← QoS                │
│  len        ← total length       │
│  data       ← pointer to payload │
│  mac_header ← L2 header          │
│  nh         ← L3 header (IP)     │
│  h          ← L4 header (TCP)    │
│  cb         ← control block      │
│  tstamp     ← packet timestamp   │
│  mark       ← netfilter mark     │
└──────────────────────────────────┘
```

The `sk_buff` is passed through the stack, and each layer moves the `data` pointer forward as it strips headers:

```
Arriving:  [Eth hdr][IP hdr][TCP hdr][Payload]
            ↑
            data pointer

After L2:   [Eth hdr][IP hdr][TCP hdr][Payload]
                     ↑
                     data pointer (eth stripped)

After L3:   [Eth hdr][IP hdr][TCP hdr][Payload]
                              ↑
                              data pointer (IP stripped)
```

### Interrupt Coalescing and NAPI

Without coalescing, every packet generates an interrupt, overwhelming the CPU at high packet rates.

```
High packet rate (bad):
Packet 1 ─→ IRQ ─→ handler ─→ process
Packet 2 ─→ IRQ ─→ handler ─→ process  ← CPU saturated with interrupts
Packet 3 ─→ IRQ ─→ handler ─→ process
...

With NAPI (good):
Packet 1 ─→ IRQ ─→ handler disables interrupts, starts polling
Packet 2 ─→ ─────→ poll() collects all packets in batch
Packet 3 ─→ ─────→ poll() collects all packets in batch
    ...               ...
                  → handler re-enables interrupts when no more packets
```

```bash
# Check if NAPI is active on an interface
cat /sys/class/net/enp0s3/gro_flush_timeout
cat /sys/class/net/enp0s3/napi_defer_hard_irqs

# Check GRO (Generic Receive Offload) stats
ethtool -S enp0s3 | grep -i gro
```

### tc — Traffic Control

The Linux traffic control system (`tc`) manages queuing disciplines:

```bash
# Show current qdisc (queue discipline)
tc qdisc show dev enp0s3

# Default qdisc: pfifo_fast (three-band priority queue)
# Alternative: fq_codel (fair queuing with controlled delay)

# Set fq_codel for better latency under load
sudo tc qdisc replace dev enp0s3 root fq_codel
```

### Key Takeaway

Every layer of the Linux network stack is modular and replaceable:
- **Driver** handles hardware specifics
- **Qdisc** manages packet queuing
- **Netfilter** provides firewall hooks
- **Neighbor subsystem** tracks L2↔L3 mappings
- **Routing tables** decide next hops
- **Network namespaces** isolate entire stacks

Understanding this stack is what separates a sysadmin who blindly copies commands from one who truly knows how Linux networks work.





[← Previous](18-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](20-command-reference.md)
