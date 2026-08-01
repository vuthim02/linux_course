## 📝 Self-Test — Can You Answer These?
1. What are the three core technologies that NFS is built on?
2. What is the fundamental difference between NFSv3 (stateless) and NFSv4 (stateful) regarding server crash recovery?
3. What does `exportfs -ra` do and when would you run it?
4. What is the difference between `root_squash` and `no_root_squash` in /etc/exports?
5. Why would you choose a soft mount over a hard mount? What is the risk?
6. How does NFSv4 eliminate the need for separate mountd, statd, and lockd daemons?
7. What is the NFSv4 pseudo-filesystem and how is it configured?
8. What does the `&` symbol mean in an autofs map file?
9. How does close-to-open consistency work in NFSv3?
10. What is the difference between `sec=krb5`, `sec=krb5i`, and `sec=krb5p`?
11. What information does `rpcinfo -p` show, and why is it important for NFSv3 troubleshooting?
12. What do high `retrans` values in `nfsstat -c` indicate?
13. How does pNFS improve NFS performance by separating metadata and data paths?
14. What is an NFSv4 delegation and what happens when the server recalls it?
15. How do NFSv4.1 sessions solve the non-idempotent operation ambiguity problem?
**Score:** 12/15 correct = ready for Part 29.
## Answer Key
### Q1: What are the three core technologies NFS is built on?
**Answer:** ONC RPC (Remote Procedure Call), XDR (External Data Representation), and the NFS protocol itself.
### Q2: What is the fundamental difference between NFSv3 and NFSv4 regarding crash recovery?
**Answer:** NFSv3 is stateless — server crashes don't affect clients (they retry). NFSv4 is stateful — clients and server maintain session state, enabling delegations and reclaiming.
### Q3: What does `exportfs -ra` do?
**Answer:** Re-reads `/etc/exports` and applies all changes without restarting the NFS server.
### Q4: What is the difference between root_squash and no_root_squash?
**Answer:** `root_squash` maps root (UID 0) to nobody (nobody:nogroup). `no_root_squash` lets remote root retain root privileges (security risk).
### Q5: Why would you choose a soft mount over a hard mount?
**Answer:** Soft mount returns an error after timeout (prevents hangs). Hard mount retries indefinitely (data integrity). Risk of soft: data loss on timeout.
### Q6: How does NFSv4 eliminate separate mountd, statd, lockd daemons?
**Answer:** NFSv4 combines everything into a single protocol/port (2049) with built-in state management, locking, and mount support.
### Q7: What is the NFSv4 pseudo-filesystem?
**Answer:** A virtual namespace root (`fsid=0`) that presents all exported paths under a unified tree, regardless of physical locations.
### Q8: What does `&` mean in an autofs map file?
**Answer:** Indirect map entry — creates a subdirectory under the mount point for each key. E.g., `* &:/shares/&` mounts `*/` as NFS shares.
### Q9: How does close-to-open consistency work in NFSv3?
**Answer:** On file close, client flushes data to server. On file open, client validates with server. Ensures consistency across clients.
### Q10: What is the difference between sec=krb5, krb5i, and krb5p?
**Answer:** `krb5` = authentication only. `krb5i` = authentication + integrity checking. `krb5p` = authentication + integrity + encryption (most secure).
### Q11: What does `rpcinfo -p` show?
**Answer:** Lists all registered RPC services on the system (including mountd, statd, lockd for NFSv3). Essential for troubleshooting NFSv3 connectivity.
### Q12: What do high `retrans` values in `nfsstat -c` indicate?
**Answer:** Many retransmissions — suggests network problems, server overload, or unstable connectivity.
### Q13: How does pNFS improve NFS performance?
**Answer:** Separates metadata and data paths. The metadata server directs clients to data servers directly, avoiding bottlenecks for large file transfers.
### Q14: What is an NFSv4 delegation?
**Answer:** Server grants a client exclusive access to a file (read or write). Client can cache locally without checking with server. Server recalls if another client accesses the file.
### Q15: How do NFSv4.1 sessions solve non-idempotent operation ambiguity?
**Answer:** Sessions use sequence numbers on each request. If a server receives a duplicate request, it recognizes the sequence and returns the cached response instead of re-executing.
*Linux SysAdmin Course | Part 28 of ∞ | Reverse Engineering Approach*
*Previous → Part 27: DNS and Name Resolution*
*Next → Part 29: Samba and Windows Interop*
[← Previous](19-whats-coming-in-part-29.md) | [↑ Index](index.md)
