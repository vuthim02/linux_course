## 6. Network Tracing — Packets, Connections, and Latency

```bash
# Trace TCP retransmits (the #1 network performance killer)
sudo tcpretrans-bpfcc

# Outgoing TCP connections
sudo tcpconnect-bpfcc

# TCP accept events (server-side)
sudo tcpaccept-bpfcc

# TCP connection lifetime with byte counts
sudo tcplife-bpfcc

# DNS resolution latency
sudo gethostlatency-bpfcc
```

### Network Simulation with tc

```bash
# Add latency
sudo tc qdisc add dev eth0 root netem delay 100ms

# Add packet loss
sudo tc qdisc add dev eth0 root netem loss 5%

# Combine delay + loss + corruption
sudo tc qdisc add dev eth0 root netem delay 50ms 10ms loss 2% corruption 1%

# View and remove rules
tc -s qdisc show dev eth0
sudo tc qdisc del dev eth0 root
```

### XDP Basics — Line-Rate Packet Processing

```
NIC Driver → XDP Program (runs BEFORE kernel sk_buff)
    Actions: PASS (to kernel) | DROP | TX (send back) | REDIRECT
    10-100x faster than iptables for filtering/DDoS mitigation
```

```bash
# Attach XDP program
sudo ip link set dev lo xdp obj xdp_drop.o sec xdp

# View XDP programs
sudo bpftool net list

# Remove XDP program
sudo ip link set dev lo xdp off
```





[← Previous](06-5-perf-the-profiling-powerhouse.md) | [↑ Index](index.md) | [Next →](08-7-filesystem-tracing-know-every.md)
