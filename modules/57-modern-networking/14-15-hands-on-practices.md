## 👨‍🍳 15 Hands-On Practices

### Practice 1: Install bpftool and bpftrace, Run execsnoop and opensnoop

```bash
# Step 1: Install tools
sudo apt update
sudo apt install -y linux-tools-$(uname -r) bpftool bpftrace

# Step 2: Check kernel support
sudo bpftool feature | grep -E "eBPF|BPF"
uname -r

# Step 3: Run execsnoop (monitor new processes)
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%-10u %-16s %s\\n", pid, comm, str(args->filename)); }'

# In another terminal, run: ls, cat, etc.

# Step 4: Run opensnoop (monitor file opens)
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%-10u %-16s %s\\n", pid, comm, str(args->filename)); }'

# Step 5: Save output to file
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%-10u %-16s %s\\n", pid, comm, str(args->filename)); }' > execsnoop.log &
sleep 10
kill %1
cat execsnoop.log
```

### Practice 2: Write bpftrace One-Liner to Count Syscalls by Process

```bash
# One-liner that counts total syscalls per process name
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); } interval:s:10 { print(@); clear(@); }'

# More detailed: show PID and COMM
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[pid, comm, probe] = count(); } interval:s:5 { printf("\\nTop syscalls:\\n"); print(@, 10); clear(@); }'

# Count specific syscall (e.g., read, write)
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_read { @reads[comm] = count(); } tracepoint:syscalls:sys_enter_write { @writes[comm] = count(); } interval:s:10 { printf("Reads:\\n"); print(@reads); printf("\\nWrites:\\n"); print(@writes); clear(@reads); clear(@writes); }'

# Practical: find which process is doing the most I/O
sudo bpftrace -e 'kprobe:vfs_read { @[comm] = count(); } interval:s:5 { printf("\\nTop I/O processes:\\n"); print(@, 5); clear(@); }'
```

### Practice 3: Write XDP Program to Drop Packets on a Specific Port

```bash
# Create the XDP program
cat > xdp_drop.c << 'XDPEOF'
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <bpf/bpf_endian.h>

SEC("xdp")
int xdp_drop_prog(struct xdp_md *ctx)
{
    void *data_end = (void *)(unsigned long)ctx->data_end;
    void *data = (void *)(unsigned long)ctx->data;
    struct ethhdr *eth = data;

    if (eth + 1 > data_end)
        return XDP_PASS;

    if (bpf_ntohs(eth->h_proto) != ETH_P_IP)
        return XDP_PASS;

    struct iphdr *ip = data + sizeof(*eth);
    if (ip + 1 > data_end)
        return XDP_PASS;

    if (ip->protocol != IPPROTO_TCP)
        return XDP_PASS;

    struct tcphdr *tcp = (void *)ip + sizeof(*ip);
    if (tcp + 1 > data_end)
        return XDP_PASS;

    if (tcp->dest == bpf_htons(9090))
        return XDP_DROP;

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
XDPEOF

# Compile
clang -O2 -target bpf -c xdp_drop.c -o xdp_drop.o

# Verify with llvm-objdump
llvm-objdump -d xdp_drop.o

# Load on test interface (use veth pair for safety)
sudo ip link set dev eth0 xdp obj xdp_drop.o

# Verify
sudo ip -d link show eth0 | grep xdp
sudo bpftool prog list | grep xdp

# Test with nc or curl
echo "test" | nc -w1 localhost 9090  # Should be dropped

# Remove
sudo ip link set dev eth0 xdp off
```

### Practice 4: Install Cilium on a kind/k3s Cluster

```bash
# Step 1: Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/

# Step 2: Create kind cluster
cat <<'EOF' | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: "none"
EOF

# Step 3: Install Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}

# Step 4: Install Cilium with kube-proxy replacement
cilium install \
  --set kubeProxyReplacement=true \
  --set ipam.mode=kubernetes

# Step 5: Wait for Cilium to be ready
cilium status --wait

# Step 6: Run connectivity test
cilium connectivity test

# Verify no kube-proxy pods
kubectl -n kube-system get pods | grep proxy
```

### Practice 5: Create Cilium Network Policies

```bash
# Deploy test applications
kubectl create deployment nginx --image=nginx
kubectl create deployment busybox --image=busybox -- sleep 3600
kubectl expose deployment nginx --port=80

# Step 1: Deny-all ingress policy
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: nginx
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: nginx
EOF

# Test: should fail
kubectl exec deploy/busybox -- wget -O- http://nginx 2>&1
# Expected: connection timeout

# Step 2: Allow specific pod-to-pod
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-busybox-to-nginx
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: nginx
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: busybox
      toPorts:
        - ports:
            - port: "80"
              protocol: TCP
EOF

# Test: should succeed
kubectl exec deploy/busybox -- wget -O- http://nginx 2>&1

# Step 3: FQDN egress policy
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-egress-fqdn
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: busybox
  egress:
    - toFQDNs:
        - matchName: example.com
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
EOF

# Test: can reach example.com but not other sites
kubectl exec deploy/busybox -- wget -O- https://example.com 2>&1
kubectl exec deploy/busybox -- wget -O- https://google.com 2>&1
```

### Practice 6: Use hubble CLI to Observe Flows

```bash
# Enable Hubble
cilium hubble enable

# Wait for Hubble to be ready
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=hubble-relay

# Port-forward Hubble
cilium hubble port-forward &

# Set hubble address
export HUBBLE_SERVER=127.0.0.1:4245

# Observe all flows
hubble observe

# Observe only flows involving a specific pod
hubble observe --pod nginx

# Observe dropped packets
hubble observe --verdict DROPPED

# Observe HTTP flows (if L7 policy is applied)
hubble observe --protocol http

# Observe flows in JSON format
hubble observe -o json --last 100

# Follow live flows
hubble observe -f

# Filter by service
hubble observe --service default/nginx

# Filter by namespace
hubble observe --namespace default

# Show flows since 5 minutes ago
hubble observe --since 5m

# Count flows by protocol
hubble observe -o json --last 1000 | jq -r '.l4 | keys[]' | sort | uniq -c
```

### Practice 7: Set Up WireGuard Tunnel Between Two Linux Servers

```bash
# On Server A (203.0.113.1)
sudo apt install wireguard
umask 077
wg genkey | tee server-a-private.key | wg pubkey > server-a-public.key

# Config /etc/wireguard/wg0.conf
sudo bash -c 'cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
Address = 10.99.99.1/30
PrivateKey = '$(cat server-a-private.key)'
ListenPort = 51820

[Peer]
PublicKey = <server-b-public>
AllowedIPs = 10.99.99.2/32
Endpoint = 203.0.113.2:51820
PersistentKeepalive = 25
WGEOF'

# On Server B (203.0.113.2)
sudo apt install wireguard
umask 077
wg genkey | tee server-b-private.key | wg pubkey > server-b-public.key

sudo bash -c 'cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
Address = 10.99.99.2/30
PrivateKey = '$(cat server-b-private.key)'
ListenPort = 51820

[Peer]
PublicKey = <server-a-public>
AllowedIPs = 10.99.99.1/32
Endpoint = 203.0.113.1:51820
PersistentKeepalive = 25
WGEOF'

# Start on both
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Verify
sudo wg show
ping -c 3 10.99.99.2  # from A
ping -c 3 10.99.99.1  # from B
```

### Practice 8: Configure WireGuard as a VPN Client

```bash
# VPN Client (your laptop)
sudo apt install wireguard
umask 077
wg genkey | tee client-private.key | wg pubkey > client-public.key

# /etc/wireguard/wg0.conf
sudo bash -c 'cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
Address = 10.99.99.100/24
PrivateKey = '$(cat client-private.key)'
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = <vpn-server-public>
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
WGEOF'

# Start
sudo wg-quick up wg0

# Verify all traffic goes through VPN
curl ifconfig.me
# Should show the VPN server's IP

# Check routes
ip route show table 51820

# Check that it works:
ping 10.99.99.1
ping 1.1.1.1

# Stop
sudo wg-quick down wg0

# Enable at boot
sudo systemctl enable wg-quick@wg0
```

### Practice 9: Create a VXLAN Interface Between Two Namespaces

```bash
# This practice uses network namespaces instead of separate hosts

# Create namespaces
sudo ip netns add ns1
sudo ip netns add ns2

# Create a veth pair to connect namespaces to the host
sudo ip link add veth1 type veth peer name veth1-br
sudo ip link add veth2 type veth peer name veth2-br

# Move one end into each namespace
sudo ip link set veth1 netns ns1
sudo ip link set veth2 netns ns2

# Create a bridge in the host
sudo ip link add br-vxlan type bridge
sudo ip link set br-vxlan up

# Attach veth pairs to bridge
sudo ip link set veth1-br master br-vxlan
sudo ip link set veth1-br up
sudo ip link set veth2-br master br-vxlan
sudo ip link set veth2-br up

# Create VXLAN interfaces inside each namespace
sudo ip netns exec ns1 ip link add vxlan1 type vxlan id 100 remote 10.0.0.2 local 10.0.0.1 dstport 4789 dev lo
sudo ip netns exec ns2 ip link add vxlan1 type vxlan id 100 remote 10.0.0.1 local 10.0.0.2 dstport 4789 dev lo

# Bring up and assign IPs
sudo ip netns exec ns1 ip addr add 10.10.0.1/24 dev vxlan1
sudo ip netns exec ns2 ip addr add 10.10.0.2/24 dev vxlan1
sudo ip netns exec ns1 ip link set vxlan1 up
sudo ip netns exec ns2 ip link set vxlan1 up

# Test
sudo ip netns exec ns1 ping -c 3 10.10.0.2

# Clean up
sudo ip netns del ns1
sudo ip netns del ns2
sudo ip link del br-vxlan
```

### Practice 10: Bridge VXLAN with Linux Bridge for L2 Extension

```bash
# On Host A (10.0.0.1)
# Create bridge
sudo ip link add br0 type bridge
sudo ip link set br0 up

# Create VXLAN interface
sudo ip link add vxlan0 type vxlan id 100 dstport 4789 local 10.0.0.1 dev eth0 nolearning

# Add VXLAN to bridge
sudo ip link set vxlan0 master br0
sudo ip link set vxlan0 up

# Add a container or VM veth
sudo ip link add veth-internal type veth peer name veth-internal-peer
sudo ip link set veth-internal-peer master br0
sudo ip link set veth-internal-peer up
sudo ip addr add 10.100.0.1/24 dev veth-internal

# Add remote VTEP (Host B at 10.0.0.2)
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan0 dst 10.0.0.2

# Verify
bridge fdb show dev vxlan0

# On Host B (10.0.0.2)
sudo ip link add br0 type bridge
sudo ip link set br0 up
sudo ip link add vxlan0 type vxlan id 100 dstport 4789 local 10.0.0.2 dev eth0 nolearning
sudo ip link set vxlan0 master br0
sudo ip link set vxlan0 up
sudo ip addr add 10.100.0.2/24 dev veth-internal
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan0 dst 10.0.0.1

# Test L2 connectivity
ping -c 3 10.100.0.2  # from Host A
# Ping MAC addresses:
arping -c 3 10.100.0.2
```

### Practice 11: Deploy Cilium with WireGuard Encryption

```bash
# Prerequisites: kind or existing K8s cluster

# Install Cilium with WireGuard encryption
cilium install \
  --set kubeProxyReplacement=true \
  --set encryption.enabled=true \
  --set encryption.type=wireguard

# Wait for rollout
cilium status --wait

# Verify WireGuard is active
cilium status | grep -i encrypt

# List WireGuard peers
cilium encrypt status

# Check the WireGuard interface
kubectl -n kube-system exec -it daemonset/cilium -- ip link show cilium_wg0

# Verify traffic is encrypted
# On a node:
sudo tcpdump -i any -nn port 51820
# You should see WireGuard traffic between nodes

# Deploy test pods
kubectl create deployment test-a --image=nginx
kubectl create deployment test-b --image=busybox -- sleep 3600
kubectl expose deployment test-a --port=80

# Test connectivity
kubectl exec -it deploy/test-b -- wget -O- http://test-a.default

# Verify encryption with Hubble
hubble observe --pod test-b --pod test-a
```

### Practice 12: Benchmark WireGuard vs iperf3

```bash
# Server side (WireGuard endpoint)
# First, set up a WireGuard tunnel between two machines
# (see Practice 7 for setup)

# On the remote server:
iperf3 -s

# On the local machine through WireGuard:
iperf3 -c 10.99.99.2 -t 30 -P 4

# Compare with direct connection (no VPN):
iperf3 -c 203.0.113.2 -t 30 -P 4

# Compare UDP throughput
iperf3 -c 10.99.99.2 -u -b 1000M -t 30

# Measure CPU usage during benchmark
# In separate terminal:
top -p $(pgrep -d',' -x wg-quick) -b -d 2

# Test with different MTU sizes
# Change MTU on wg0:
sudo ip link set wg0 mtu 1280
iperf3 -c 10.99.99.2 -t 30

# Test latency
ping -c 100 10.99.99.2 | tail -2
# Compare:
ping -c 100 203.0.113.2 | tail -2
```

### Practice 13: Set Up Hubble UI to Visualize Service Map

```bash
# Step 1: Enable Hubble UI
cilium hubble enable --ui

# Wait for UI pod
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=hubble-ui

# Step 2: Port-forward to access UI
cilium hubble ui &

# Or manually:
kubectl -n kube-system port-forward service/hubble-ui 12000:80

# Open browser to http://localhost:12000

# Step 3: Generate traffic to see the service map
kubectl run -it --rm load-generator --image=busybox -- /bin/sh
# Inside the pod:
while true; do wget -q -O- http://nginx.default; sleep 0.5; done

# Step 4: Observe in Hubble UI
# - Service Map tab: see real-time graph
# - Flow tab: see individual flows
# - Click on pods to inspect their traffic

# Step 5: Add L7 policy to see HTTP flows
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: hubble-l7-visibility
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: nginx
  ingress:
    - toPorts:
        - ports:
            - port: "80"
              protocol: TCP
          rules:
            http:
              - method: GET
EOF

# Now Hubble UI will show L7 information (HTTP methods, paths, status codes)
```

### Practice 14: Create Cilium L7 Policy to Restrict HTTP Paths

```bash
# Deploy a backend service with different paths
kubectl create deployment httpbin --image=mccutchen/go-httpbin
kubectl expose deployment httpbin --port=8080
kubectl create deployment curl-pod --image=curlimages/curl -- sleep 3600

# Test unrestricted access
kubectl exec curl-pod -- curl -s http://httpbin:8080/get
kubectl exec curl-pod -- curl -s http://httpbin:8080/post -X POST
kubectl exec curl-pod -- curl -s http://httpbin:8080/delete -X DELETE
kubectl exec curl-pod -- curl -s http://httpbin:8080/status/500

# Apply L7 policy restricting paths
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-httpbin
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: httpbin
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: curl-pod
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: "/get"
              - method: GET
                path: "/status/200"
              - method: POST
                path: "/post"
EOF

# Test allowed paths
kubectl exec curl-pod -- curl -s http://httpbin:8080/get
kubectl exec curl-pod -- curl -s http://httpbin:8080/status/200
kubectl exec curl-pod -- curl -s http://httpbin:8080/post -X POST

# Test denied paths
kubectl exec curl-pod -- curl -s http://httpbin:8080/delete -X DELETE
kubectl exec curl-pod -- curl -s http://httpbin:8080/status/500
kubectl exec curl-pod -- curl -s http://httpbin:8080/anything

# Observe dropped requests in Hubble
hubble observe --pod httpbin --verdict DROPPED
```

### Practice 15: Real-World Integration — Multi-Node Kubernetes with Cilium

```bash
# ┌────────────────────────────────────────────────────────────────────────┐
# │ REAL-WORLD INTEGRATION                                                 │
# │                                                                        │
# │ Deploy a multi-node Kubernetes cluster with:                           │
# │   • Cilium with eBPF networking (kube-proxy replacement)               │
# │   • CiliumNetworkPolicies (L3/L4/L7)                                   │
# │   • Hubble observability (service map + flow logs)                     │
# │   • WireGuard encryption (pod-to-pod traffic encrypted)                │
# │   • VXLAN overlay (if using Cilium in tunneling mode)                  │
# └────────────────────────────────────────────────────────────────────────┘

# Step 1: Create multi-node kind cluster
cat <<'EOF' | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: "none"
EOF

# Step 2: Install Cilium with all features
cilium install \
  --set kubeProxyReplacement=true \
  --set encryption.enabled=true \
  --set encryption.type=wireguard \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# Wait for everything
cilium status --wait

# Step 3: Verify the setup
echo "=== Cilium Status ==="
cilium status

echo "=== Encryption ==="
cilium encrypt status

echo "=== Hubble ==="
cilium hubble status

# Step 4: Deploy microservices
kubectl create deployment frontend --image=nginx
kubectl create deployment api-server --image=mccutchen/go-httpbin
kubectl create deployment db --image=postgres:13-alpine --env="POSTGRES_PASSWORD=test"
kubectl expose deployment frontend --port=80
kubectl expose deployment api-server --port=8080
kubectl expose deployment db --port=5432

# Step 5: Apply defense-in-depth policies

# Default deny-all for all services
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  endpointSelector:
    matchLabels: {}
  ingress:
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
            - port: "53"
              protocol: TCP
  egress:
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
            - port: "53"
              protocol: TCP
EOF

# Allow frontend → api-server (L7 aware)
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: frontend-to-api
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: "/get"
              - method: GET
                path: "/status/200"
              - method: POST
                path: "/post"
EOF

# Allow api-server → db
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-to-db
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: db
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: api-server
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
EOF

# Allow egress to external API (FQDN based)
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-egress-external
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  egress:
    - toFQDNs:
        - matchPattern: "*.example.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
EOF

# Step 6: Test connectivity
echo "=== Testing frontend → api-server ==="
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl -s http://frontend:80/

echo "=== Testing api-server → db ==="
kubectl exec -it deploy/api-server -- sh -c \
  'apt-get update && apt-get install -y postgresql-client && \
   PGPASSWORD=test psql -h db -U postgres -c "\\l"'

# Step 7: Observe with Hubble
echo "=== Hubble Flow Log ==="
cilium hubble port-forward &
sleep 2
hubble observe --since 5m --verdict FORWARDED | head -20

echo "=== Hubble Dropped Flows ==="
hubble observe --since 5m --verdict DROPPED

# Step 8: Verify WireGuard encryption
echo "=== WireGuard Peers ==="
kubectl -n kube-system exec daemonset/cilium -- wg show

# Step 9: Access Hubble UI
echo "=== Hubble UI available at: ==="
echo "http://localhost:12000"
kubectl -n kube-system port-forward service/hubble-ui 12000:80 &

echo "=== Integration Complete ==="
echo "Multi-node Kubernetes cluster with:"
echo "  eBPF datapath (no iptables)"
echo "  kube-proxy replacement"
echo "  CiliumNetworkPolicies (L3/L4/L7)"
echo "  Hubble observability"
echo "  WireGuard encryption"
echo "  FQDN-based egress policies"
```





[← Previous](13-section-12-performance-and-tuning.md) | [↑ Index](index.md) | [Next →](15-deep-understanding.md)
