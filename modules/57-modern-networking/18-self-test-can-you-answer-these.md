## 📝 Self-Test — Can You Answer These?

1. What are the three components the eBPF verifier checks before allowing a program to run, and why is JIT compilation important for performance?

2. How does an XDP program access packet data differently from a tc program? What data structure does each receive?

3. What are the five possible return values from an XDP program, and what does each do?

4. How does Cilium's eBPF datapath achieve O(1) service translation compared to iptables O(n)?

5. In a CiliumNetworkPolicy, what is the difference between `endpointSelector`, `fromEndpoints`, `toEndpoints`, and `toFQDNs`?

6. How does an L7 Cilium policy inspect HTTP paths and methods when the traffic is encrypted with TLS?

7. What information does Hubble's service map display, and how does it collect flow data without a central aggregation bottleneck?

8. Draw the WireGuard handshake message sequence. What cryptographic primitives are used at each step?

9. How does WireGuard handle a client that changes its IP address (roaming) without re-establishing the tunnel?

10. What is the purpose of `PersistentKeepalive` in a WireGuard configuration, and what problem does it solve?

11. A VXLAN packet is received on UDP port 4789. Walk through the kernel's decapsulation steps from `eth0` to the final bridge delivery.

12. What is the MTU of a VXLAN interface if the physical link is 1500 bytes? Show the calculation including all overhead.

13. In the FRR + VXLAN (EVPN) architecture, what does BGP distribute, and how does it eliminate the need for multicast or flooding for MAC learning?

14. When Cilium encrypts pod-to-pod traffic with WireGuard, where does the encryption happen in the network path? What BPF programs are involved?

15. You have a Kubernetes cluster with 500 nodes and 10,000 services. Explain why Cilium's eBPF approach scales better than kube-proxy with iptables at this scale.

**Score:** 12/15 correct = ready for Part 58.


## Answer Key

### Q1: What does the eBPF verifier check and why is JIT important?
**Answer:** Verifier checks: no infinite loops, no out-of-bounds access, no null derefs, bounded execution, valid helper calls. JIT compiles eBPF bytecode to native machine code for near-zero overhead.

### Q2: How does XDP differ from tc in packet access?
**Answer:** XDP gets raw `xdp_buff` (pre-SKB, line rate). tc gets `sk_buff` (after full kernel network stack processing). XDP is faster but has fewer features.

### Q3: Five XDP return values.
**Answer:** `XDP_PASS` (pass up stack), `XDP_DROP` (drop packet), `XDP_TX` (return out same NIC), `XDP_REDIRECT` (send to another NIC/CPU), `XDP_ABORTED` (drop + trace).

### Q4: How does Cilium achieve O(1) service translation?
**Answer:** eBPF programs are compiled and attached per-node. Service lookups use hash maps (O(1)) instead of iptables linear chain traversal (O(n)).

### Q5: CiliumNetworkPolicy selector fields.
**Answer:** `endpointSelector` = which pods the policy applies to. `fromEndpoints` = allowed sources. `toEndpoints` = allowed destinations. `toFQDNs` = allowed external domains.

### Q6: How does L7 policy inspect encrypted TLS traffic?
**Answer:** Cilium uses a TLS-aware proxy (Envoy) that terminates TLS inside the pod namespace, inspects L7 rules, and re-encrypts before forwarding.

### Q7: Hubble's service map and flow data collection.
**Answer:** Hubble reads eBPF maps from each node (no central aggregation). Flow data is collected per-node via ring buffer. Service map visualizes L3/L7 dependencies from flow data.

### Q8: WireGuard handshake message sequence.
**Answer:** Initiation (IK): initiator sends ephemeral public key + encrypted payload (Noise IK). Response: responder sends its ephemeral key + encrypted cookie. Both derive shared secret via Curve25519.

### Q9: How does WireGuard handle client IP roaming?
**Answer:** WireGuard identifies peers by public key, not IP. When a packet arrives from a new source IP, WireGuard updates the endpoint automatically — no re-keying needed.

### Q10: What does PersistentKeepalive do?
**Answer:** Sends a keepalive packet every N seconds to maintain the NAT mapping. Without it, NAT firewalls may drop the UDP mapping after inactivity, breaking incoming connections.

### Q11: VXLAN decapsulation steps.
**Answer:** 1) UDP packet arrives on port 4789, 2) Kernel matches to VXLAN tunnel, 3) Outer headers stripped, 4) Inner Ethernet frame delivered to VTEP bridge, 5) Bridge forwards based on MAC table.

### Q12: VXLAN MTU calculation.
**Answer:** Physical MTU 1500 - outer IP (20) - outer UDP (8) - VXLAN header (8) - outer Ethernet (14) = **1450 bytes** payload. Inner MTU = 1450.

### Q13: What does BGP distribute in FRR+VXLAN(EVPN)?
**Answer:** BGP distributes EVPN routes: MAC/IP bindings, VTEP reachability, and prefix routes. Eliminates flooding by advertising learnings via BGP instead of multicast.

### Q14: Where does Cilium's WireGuard encryption happen?
**Answer:** Encryption happens at the eBPF socket level (tc hook) before the packet enters the network stack. BPF programs encrypt/decrypt at the node boundary.

### Q15: Why does Cilium scale better than kube-proxy+iptables?
**Answer:** iptables: O(n) per packet (linear rule traversal). With 10K services × 5 endpoints = 50K rules. Cilium: O(1) via eBPF hash maps, no linear scan, per-CPU lookups.


*Linux SysAdmin Course | Part 57 of ∞ | Reverse Engineering Approach*
*Previous → Part 56: Observability Deep Dive*
*Next → Part 58: Secrets Management*


[← Previous](part56.md) | [Next →](part58.md)



[← Previous](17-whats-coming-in-part-58.md) | [↑ Index](index.md)
