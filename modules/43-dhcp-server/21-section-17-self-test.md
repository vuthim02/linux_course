## ✅ Section 17: Self-Test

**Instructions:** Answer each question. **Score:** 12/15 correct = ready for Part 44.

### Questions

**Q1:** What does DORA stand for, and what happens in each step?

**Q2:** A client boots up and gets IP `169.254.23.45` instead of a valid DHCP address. What is this address called and what does it indicate?

**Q3:** Write the `dhcpd.conf` configuration for a subnet `10.0.0.0/24` with range `10.0.0.100` to `10.0.0.200`, gateway `10.0.0.1`, DNS `8.8.8.8` and `1.1.1.1`, lease time 12 hours.

**Q4:** What is the purpose of the `giaddr` field in a DHCP packet, and which network device sets it?

**Q5:** You added a static reservation for a printer with MAC `00:11:22:33:44:55` and fixed-address `192.168.1.10`, but the printer got `192.168.1.150` instead. What are three possible causes?

**Q6:** What is the difference between T1 (renewal) and T2 (rebinding) in the DHCP lease lifecycle?

**Q7:** Write the configuration for a DHCP failover peer declaration. What is the purpose of `mclt` and `split`?

**Q8:** What are DHCP options 66 and 67 used for? What is the difference between BIOS and UEFI PXE boot regarding these options?

**Q9:** You run `sudo dhcpd -t` and get "subnet 10.0.0.0 netmask 255.255.255.0: no address range." What is the problem and how do you fix it?

**Q10:** What is the difference between ISC DHCP and Kea? List at least three differences.

**Q11:** In DHCPv6, what is the difference between stateful and stateless DHCPv6? What is IA_PD used for?

**Q12:** A DHCP relay is configured but clients on the remote subnet are not getting IPs. Write three debugging commands you would run.

**Q13:** What does the `authoritative;` directive do? What happens if you omit it?

**Q14:** What is the magic cookie in DHCP? What is its hex value?

**Q15:** You have two DHCP servers configured for failover. The primary crashes. What state does the secondary enter? How does it recover when the primary comes back?

### Answer Key

**A1:**
- **D**iscover: Client broadcasts "is there a DHCP server?"
- **O**ffer: Server responds "you can use IP X"
- **R**equest: Client says "I accept IP X"
- **A**cknowledge: Server confirms "IP X is yours, here are options"

**A2:** `169.254.x.x` is an **APIPA** (Automatic Private IP Addressing) address. It indicates the client sent a DHCPDISCOVER but **received no response** (no DHCP server reachable). The client self-assigns a link-local address.

**A3:**
```bash
subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.100 10.0.0.200;
    option routers 10.0.0.1;
    option domain-name-servers 8.8.8.8, 1.1.1.1;
    default-lease-time 43200;
    max-lease-time 86400;
}
```

**A4:** The **giaddr** (Gateway IP Address) tells the DHCP server which subnet the client is on. It is set by the **DHCP relay agent** (router or Linux dhcrelay). The relay sets giaddr to its own IP on the client's subnet.

**A5:** (1) The MAC address in the reservation is wrong. (2) The `fixed-address` is inside the dynamic range — move it outside. (3) There is a typo in `hardware ethernet` or the host block is not inside the correct subnet. (4) Config was not reloaded.

**A6:** **T1** (Renewal, 50% of lease): Client unicasts DHCPREQUEST to the original server. **T2** (Rebinding, 87.5%): If T1 failed, client broadcasts DHCPREQUEST to any server.

**A7:**
```bash
failover peer "dhcp-failover" {
    primary; address 192.168.1.10; port 647;
    peer address 192.168.1.11; peer port 647;
    max-response-delay 30; mclt 3600; split 128;
}
```
- **mclt**: Maximum Client Lead Time — prevents split-brain
- **split**: Load balancing ratio (128 = 50/50)

**A8:** Option **66** (tftp-server-name) specifies the TFTP server. Option **67** (bootfile-name) specifies the boot file. **BIOS** uses `pxelinux.0`; **UEFI** uses `bootx64.efi` (x64) or `bootia32.efi` (IA32).

**A9:** The subnet has no `range` statement. Every dynamic subnet needs at least one `range` directive. Fix: add `range 10.0.0.100 10.0.0.200;`.

**A10:**
1. **Config format**: ISC uses flat file; Kea uses **JSON**
2. **Database**: ISC uses flat files; Kea supports **MySQL/PostgreSQL**
3. **Performance**: Kea is **multi-threaded**; ISC is single-threaded
4. **API**: Kea has **REST API**; ISC has none
5. **Extensibility**: Kea has **hooks** library system

**A11:** **Stateful DHCPv6** assigns addresses + options. **Stateless DHCPv6** (SLAAC + info): clients self-assign addresses via RA, DHCPv6 provides DNS/NTP only. **IA_PD** (Prefix Delegation) assigns an entire IPv6 prefix to a downstream router.

**A12:**
1. `sudo tcpdump -i eth0 port 67 or port 68 -n` — verify packets reach relay
2. `sudo systemctl status isc-dhcp-relay` — check relay is running
3. `sudo dhcrelay -d 192.168.1.10` — run relay in debug mode
4. `sysctl net.ipv4.ip_forward` — check IP forwarding is enabled

**A13:** `authoritative;` tells the server to send **DHCPNAK** to clients with IPs from the wrong subnet (forcing them to get a correct one). Without it, the server is **timid** and ignores such requests.

**A14:** The magic cookie is a 4-byte value (`0x63825363`) at the start of the options field, distinguishing DHCP from BOOTP.

**A15:** The secondary enters **partner-down** state, serving leases from the primary's pool. When the primary returns, the secondary enters **recover** state, sends its lease database via BNDUPD, both servers synchronize and return to **normal**.

### Scoring

| Score | Result |
|-------|--------|
| **15/15** | Perfect — you are ready for mail servers |
| **12–14/15** | Strong understanding — proceed to Part 44 |
| **9–11/15** | Review the sections you missed |
| **< 9/15** | Re-read Part 43 and practice with the 15 exercises |

**Score:** ___/15 correct = ready for Part 44.





[← Previous](20-section-16-whats-coming-in.md) | [↑ Index](index.md) | [Next →](22-quick-reference-cards.md)
