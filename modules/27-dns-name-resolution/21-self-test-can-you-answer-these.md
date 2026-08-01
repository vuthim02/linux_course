## 📝 Self-Test — Can You Answer These?
1. What is the difference between a recursive and iterative DNS query?
2. What are the three services (sources) listed in the default `hosts` line of `/etc/nsswitch.conf`?
3. Why does `dig google.com` work even when `ping google.com` fails with "Temporary failure in name resolution"?
4. What does `options timeout:2` in `/etc/resolv.conf` control?
5. What is the purpose of the stub resolver at `127.0.0.53`?
6. How does `dig +trace` work? What servers does it contact?
7. What is the difference between mDNS and LLMNR?
8. How do you flush the DNS cache on a system using systemd-resolved?
9. What record type would you query to find a domain's mail servers?
10. What does `search example.com` in `/etc/resolv.conf` do?
11. How does TCP wrappers (`/etc/hosts.allow`, `/etc/hosts.deny`) decide whether to allow a connection?
12. What is the TTL field in a DNS response, and how does it affect caching?
13. How would you block `facebook.com` on a Linux machine using only local configuration files?
14. What is the difference between `nscd -i hosts` and `resolvectl flush-caches`?
15. When you call `getaddrinfo()` in a C program, in what order does glibc consult `files`, `dns`, and `myhostname`?
**Score:** 12/15 correct = ready for Part 28.
## Answer Key
### Q1: What is the difference between a recursive and iterative DNS query?
**Answer:** Recursive: client asks server to resolve fully and return the answer. Iterative: server returns the best answer it has (may be a referral to another server).
### Q2: What are the three services in the default `hosts` line of nsswitch.conf?
**Answer:** `files` (/etc/hosts), `dns` (/etc/resolv.conf resolvers), `mymachine` (systemd-resolved local entries).
### Q3: Why does `dig` work when `ping` fails with name resolution error?
**Answer:** `dig` queries DNS directly. `ping` goes through glibc's getaddrinfo(), which uses nsswitch.conf (may fail if NSS config or resolv.conf differs from dig's resolver).
### Q4: What does `options timeout:2` in resolv.conf control?
**Answer:** Sets the DNS query timeout to 2 seconds per nameserver before trying the next one or failing.
### Q5: What is the purpose of the stub resolver at 127.0.0.53?
**Answer:** A local DNS proxy that provides caching, DNSSEC validation, per-link DNS resolution, and mDNS/LLMNR resolution.
### Q6: How does `dig +trace` work?
**Answer:** Simulates full iterative resolution: queries root servers → TLD servers → authoritative servers, showing each delegation step.
### Q7: What is the difference between mDNS and LLMNR?
**Answer:** mDNS (multicast DNS, port 5353) uses `.local` names. LLMNR (Link-Local Multicast Name Resolution) is Windows/Linux fallback for LAN name resolution without DNS.
### Q8: How do you flush DNS cache on systemd-resolved?
**Answer:** `resolvectl flush-caches` or `sudo systemd-resolve --flush-caches`
### Q9: What record type finds a domain's mail servers?
**Answer:** MX (Mail Exchange) records — `dig example.com MX`
### Q10: What does `search example.com` in resolv.conf do?
**Answer:** When you query a short name (e.g., `web`), it appends `example.com` and tries `web.example.com` automatically.
### Q11: How does TCP wrappers decide whether to allow a connection?
**Answer:** Checks `/etc/hosts.allow` first (if matched, allow). Then `/etc/hosts.deny` (if matched, deny). Default: allow.
### Q12: What is the TTL field in a DNS response?
**Answer:** Time To Live — how many seconds the response can be cached. Lower TTL = more frequent lookups but faster propagation of changes.
### Q13: How would you block facebook.com using local config files?
**Answer:** Add `127.0.0.1 facebook.com www.facebook.com` to `/etc/hosts`.
### Q14: What is the difference between `nscd -i hosts` and `resolvectl flush-caches`?
**Answer:** `nscd -i hosts` flushes the Name Service Cache Daemon's host cache. `resolvectl flush-caches` flushes systemd-resolved's DNS cache. Different caches.
### Q15: When you call `getaddrinfo()`, in what order does glibc consult files, dns, and myhostname?
**Answer:** Order specified in `/etc/nsswitch.conf` `hosts:` line. Default: `files dns myhostname` — checks /etc/hosts first, then DNS, then local hostname.
*Linux SysAdmin Course | Part 27 of ∞ | Reverse Engineering Approach*
*Previous → Part 26: Network Configuration*
*Next → Part 28: Network File System (NFS)*
[← Previous](20-whats-coming-in-part-28.md) | [↑ Index](index.md)
