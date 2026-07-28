## 📋 Command Reference

### eBPF / bpftool

| Command | Description |
|---------|-------------|
| `sudo bpftool prog list` | List all loaded eBPF programs |
| `sudo bpftool map list` | List all eBPF maps |
| `sudo bpftool prog dump xlated id N` | Disassemble BPF bytecode |
| `sudo bpftool prog dump jited id N` | Show JIT-compiled machine code |
| `sudo bpftool prog pin id N /sys/fs/bpf/prog` | Pin program to BPF filesystem |
| `sudo bpftool map dump id N` | Dump all entries in a map |
| `sudo bpftool map update id N key HEX value HEX` | Update a map entry |
| `sudo bpftool net list` | Show network-attached BPF programs |
| `sudo bpftool feature` | Show kernel eBPF feature support |
| `sudo mount -t bpf bpffs /sys/fs/bpf` | Mount BPF filesystem |

### bpftrace

| Command | Description |
|---------|-------------|
| `sudo bpftrace -e 'probe { action }'` | Run one-liner |
| `sudo bpftrace script.bt` | Run script file |
| `sudo bpftrace -l 'tracepoint:syscalls:*'` | List available probes |
| `sudo bpftrace -v -e '...'` | Verbose (show compilation) |
| `sudo bpftrace --btf` | Use BTF for type info |

### XDP

| Command | Description |
|---------|-------------|
| `sudo ip link set dev eth0 xdp obj prog.o` | Load XDP program (native) |
| `sudo ip link set dev eth0 xdpgeneric obj prog.o` | Load XDP (generic mode) |
| `sudo ip link set dev eth0 xdp off` | Remove XDP program |
| `sudo ip -d link show eth0` | Show XDP attachment |
| `sudo bpftool net attach xdp id N dev eth0` | Attach XDP by program ID |
| `clang -O2 -target bpf -c prog.c -o prog.o` | Compile BPF program |
| `llvm-objdump -d prog.o` | Disassemble BPF object file |

### Cilium

| Command | Description |
|---------|-------------|
| `cilium install --set kubeProxyReplacement=true` | Install Cilium |
| `cilium status` | Check Cilium status |
| `cilium connectivity test` | Run connectivity tests |
| `cilium bpf service list` | Show service-to-backend mappings |
| `cilium bpf nat list` | Show NAT table |
| `cilium bpf lb list` | Show load balancer tables |
| `cilium encrypt status` | Show encryption status |
| `cilium hubble enable --ui` | Enable Hubble with UI |
| `cilium hubble port-forward` | Port-forward Hubble |
| `cilium clustermesh enable` | Enable ClusterMesh |
| `cilium config set KEY VALUE` | Set Cilium config |

### Hubble

| Command | Description |
|---------|-------------|
| `hubble observe` | Observe all flows |
| `hubble observe --pod NAME` | Filter by pod |
| `hubble observe --namespace NS` | Filter by namespace |
| `hubble observe --verdict DROPPED` | Show only dropped packets |
| `hubble observe --protocol http` | Show only HTTP flows |
| `hubble observe --since 5m` | Flows from last 5 minutes |
| `hubble observe -o json` | JSON output |
| `hubble observe -f` | Follow mode |
| `hubble status` | Hubble connection status |

### WireGuard

| Command | Description |
|---------|-------------|
| `wg genkey` | Generate private key |
| `wg pubkey < private.key` | Derive public key from private |
| `wg genpsk` | Generate pre-shared key |
| `wg-quick up wg0` | Bring up WireGuard interface |
| `wg-quick down wg0` | Bring down WireGuard interface |
| `wg show` | Show WireGuard status |
| `wg showconf wg0` | Show full configuration |
| `wg set wg0 peer PUBKEY endpoint IP:PORT` | Update peer endpoint |
| `wg set wg0 peer PUBKEY allowed-ips CIDR` | Update allowed IPs |
| `systemctl enable wg-quick@wg0` | Enable at boot |
| `modinfo wireguard` | Check if WireGuard module exists |

### VXLAN

| Command | Description |
|---------|-------------|
| `sudo ip link add vxlan0 type vxlan id 100 dev eth0 remote 10.0.0.2` | Create VXLAN interface |
| `sudo ip link add vxlan0 type vxlan id 100 group 239.1.1.1 dev eth0` | VXLAN with multicast |
| `sudo ip -d link show vxlan0` | Show VXLAN details |
| `sudo ip link set vxlan0 mtu 1450` | Set MTU for VXLAN |
| `sudo ip link del vxlan0` | Delete VXLAN interface |
| `sudo bridge fdb show dev vxlan0` | Show FDB entries for VXLAN |
| `sudo bridge fdb append MAC dev vxlan0 dst IP` | Add FDB entry |

### Performance

| Command | Description |
|---------|-------------|
| `sudo ethtool -k eth0` | Show offload settings |
| `sudo ethtool -K eth0 gro off` | Disable GRO |
| `sudo ethtool -K eth0 tx-udp_tnl-segmentation off` | Disable UDP tunnel segmentation |
| `sudo ip link set eth0 mtu 9000` | Set jumbo frames |
| `sudo sysctl -w net.core.rmem_max=26214400` | Increase UDP buffer size |
| `iperf3 -c HOST -t 30 -P 4` | Benchmark throughput |
| `ping -M do -s 1472 HOST` | Test MTU |





[← Previous](15-deep-understanding.md) | [↑ Index](index.md) | [Next →](17-whats-coming-in-part-58.md)
