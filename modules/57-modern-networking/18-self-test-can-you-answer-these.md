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

---

*Linux SysAdmin Course | Part 57 of ∞ | Reverse Engineering Approach*
*Previous → Part 56: Observability Deep Dive*
*Next → Part 58: Secrets Management*


[← Previous](part56.md) | [Next →](part58.md)


---

[← Previous](17-whats-coming-in-part-58.md) | [↑ Index](index.md)
