## 📝 Self-Test: 15 Questions
**Score 12/15 correct = ready for Part 43.**
**Q1:** What is the difference between an authoritative-only BIND server and a recursive resolver?
<details>
<summary>Answer</summary>
Authoritative-only serves configured zones and refuses recursion. Recursive resolvers query upstream servers for clients and cache results. Authoritative uses `recursion no`; recursive uses `recursion yes` with restricted `allow-recursion`.
</details>
**Q2:** What three things must you do after modifying a zone file?
<details>
<summary>Answer</summary>
1. Increment the SOA serial number. 2. Run `named-checkzone <zone> <file>`. 3. Run `sudo rndc reload` or `sudo systemctl reload named`.
</details>
**Q3:** What does `$ORIGIN` do in a zone file?
<details>
<summary>Answer</summary>
Sets the default domain suffix. Unqualified names (no trailing dot) have `$ORIGIN` appended: `$ORIGIN example.com.` makes `www` become `www.example.com.`
</details>
**Q4:** How do you set up reverse DNS for `192.168.1.0/24`? What is the zone name?
<details>
<summary>Answer</summary>
Zone name: `1.168.192.in-addr.arpa`. Create zone statement with `type master` and a zone file containing PTR records mapping host portions (e.g., `100 IN PTR www.example.com.`).
</details>
**Q5:** What is the difference between AXFR and IXFR?
<details>
<summary>Answer</summary>
AXFR transfers the entire zone. IXFR transfers only changed records (incremental). IXFR is more efficient for large zones.
</details>
**Q6:** What does TSIG provide for zone transfers?
<details>
<summary>Answer</summary>
Cryptographic authentication via HMAC shared secret. Ensures only authorized servers receive zone data, preventing data leakage.
</details>
**Q7:** In DNSSEC, what is the difference between KSK and ZSK?
<details>
<summary>Answer</summary>
KSK (Key Signing Key, 4096-bit) signs the DNSKEY set; its fingerprint is published in the parent zone as a DS record. ZSK (Zone Signing Key, 2048-bit) signs all other records. ZSK can be rolled over more frequently without parent involvement.
</details>
**Q8:** How does `dig +trace` work?
<details>
<summary>Answer</summary>
Simulates full resolution from root servers: queries root → TLD → authoritative, printing delegation at each step. Reveals where resolution succeeds or fails.
</details>
**Q9:** What does SERVFAIL typically indicate?
<details>
<summary>Answer</summary>
Server failure: zone file error (zone not loaded), DNSSEC validation failure, upstream timeout, or resource exhaustion.
</details>
**Q10:** How do you restrict zone transfers to trusted slaves?
<details>
<summary>Answer</summary>
Use `allow-transfer` in zone statement with IP addresses or TSIG key. Set `allow-transfer { none; };` in global options as default.
</details>
**Q11:** What does `rndc flush` do?
<details>
<summary>Answer</summary>
Clears all cached DNS records. Use when you need immediate re-resolution (cannot wait for TTL expiry after a critical change).
</details>
**Q12:** What is split DNS (views)?
<details>
<summary>Answer</summary>
BIND serves different DNS data based on client source IP. Internal clients see private IPs; external clients see public IPs. Uses `view` blocks with `match-clients`.
</details>
**Q13:** What are the minimum required records in every authoritative zone file?
<details>
<summary>Answer</summary>
SOA record with serial/refresh/retry/expire/minimum, at least one NS record, and matching A/AAAA records for each NS (glue).
</details>
**Q14:** How do you enable query logging from the command line without restarting?
<details>
<summary>Answer</summary>
`sudo rndc querylog on` (off to disable). Requires a `logging` category for `queries` in `named.conf`.
</details>
**Q15:** What does a slave DNS server do on startup for each slave zone?
<details>
<summary>Answer</summary>
Queries master's SOA, compares serial numbers. If master's serial is higher, initiates AXFR/IXFR. If serials match, serves cached zone data.
</details>
**Score:** ___ / 15
| Score | Assessment |
|-------|-----------|
| 12–15 | Ready for Part 43: DHCP Server |
| 9–11 | Review sections 4, 5, 8, 12 |
| 0–8 | Review entire part and hands-on practices |
*Previous → Part 41: LDAP and Centralized Authentication*
*Next → Part 43: DHCP Server*
[← Previous](20-whats-coming-in-part-43.md) | [↑ Index](index.md)
