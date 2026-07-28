## 3. Network Namespace

### The Network Isolation Model

Each network namespace gets its own complete network stack: interfaces, IP addresses, routing tables, port numbers, iptables rules, and `/proc/net` statistics.

```
┌─────────────────────────────────────────────────────────────────┐
│  HOST NETWORK NAMESPACE                                          │
│                                                                  │
│  eth0: 192.168.1.100 (physical NIC)                             │
│  docker0: 172.17.0.1/16 (bridge)                                │
│  veth-host@if2: → veth-container@if1                            │
│                                                                  │
│  ┌─────────────────────────┐  ┌─────────────────────────┐      │
│  │  Container A (net NS)   │  │  Container B (net NS)   │      │
│  │  lo: 127.0.0.1          │  │  lo: 127.0.0.1          │      │
│  │  eth0@if1: 172.17.0.2   │  │  eth0@if1: 172.17.0.3   │      │
│  │  gw: 172.17.0.1         │  │  gw: 172.17.0.1         │      │
│  └──────────┬──────────────┘  └──────────┬──────────────┘      │
│             │                             │                      │
│          veth pair                    veth pair                  │
│             │                             │                      │
│             └─────────┬───────────────────┘                      │
│                       │                                          │
│                  docker0 bridge                                   │
│                       │                                          │
│                    iptables NAT                                   │
│                       │                                          │
│                    eth0 → internet                               │
└─────────────────────────────────────────────────────────────────┘
```

### veth Pairs

Virtual ethernet (veth) pairs are tunnel endpoints — packets entering one end come out the other.

```bash
# Create a network namespace
sudo ip netns add container_a

# Create a veth pair
sudo ip link add veth-host type veth peer name veth-ns

# Move one end into the namespace
sudo ip link set veth-ns netns container_a

# Configure the host end
sudo ip addr add 10.200.1.1/24 dev veth-host
sudo ip link set veth-host up

# Configure the namespace end
sudo ip netns exec container_a ip addr add 10.200.1.2/24 dev veth-ns
sudo ip netns exec container_a ip link set veth-ns up
sudo ip netns exec container_a ip link set lo up

# Test connectivity
ping 10.200.1.2   # From host → container
sudo ip netns exec container_a ping 10.200.1.1  # Container → host
```

### Bridge Networking

```bash
# Create a bridge
sudo ip link add br0 type bridge
sudo ip addr add 10.200.0.1/24 dev br0
sudo ip link set br0 up

# Enable bridge to forward (like Docker does)
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0

# Create namespaces and connect via veth pairs
for i in 1 2 3; do
    sudo ip netns add ns${i}
    sudo ip link add veth${i}-host type veth peer name veth${i}-ns
    sudo ip link set veth${i}-ns netns ns${i}
    sudo ip link set veth${i}-host master br0
    sudo ip link set veth${i}-host up
    sudo ip netns exec ns${i} ip addr add 10.200.0.${i}/24 dev veth${i}-ns
    sudo ip netns exec ns${i} ip link set veth${i}-ns up
    sudo ip netns exec ns${i} ip link set lo up
done

# All three namespaces can now communicate through the bridge
sudo ip netns exec ns1 ping 10.200.0.2
sudo ip netns exec ns2 ping 10.200.0.3
```

### NAT and Internet Access

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Add NAT rule so containers reach the internet
sudo iptables -t nat -A POSTROUTING -s 10.200.0.0/24 -o eth0 -j MASQUERADE

# Add default route inside namespaces
sudo ip netns exec ns1 ip route add default via 10.200.0.1

# Now ns1 can reach the internet
sudo ip netns exec ns1 ping -c 2 8.8.8.8
```

### Network Namespace Inspection

```bash
# List all network namespaces
sudo ip netns list
# container_a
# ns1
# ns2
# ns3

# Execute command in a namespace
sudo ip netns exec container_a ip addr show

# Enter a namespace interactively
sudo ip netns exec container_a bash

# View iptables rules inside a namespace
sudo ip netns exec container_a iptables -L -n

# Check /proc/net inside a namespace
sudo ip netns exec container_a cat /proc/net/tcp

# Move an existing process into a network namespace (requires privileges)
# This is useful for attaching a running process to a container network
```

> 🔍 **Reverse Engineering Insight:** Every container gets its own port space. Two containers can both bind to port 8080 because they exist in separate network namespaces. This is why `-p 8080:80` in Docker maps the host port to the container port — it's bridging two different network namespaces.





[← Previous](03-2-pid-namespace.md) | [↑ Index](index.md) | [Next →](05-4-mount-namespace.md)
