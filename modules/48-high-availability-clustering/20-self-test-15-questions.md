## ✅ Self-Test: 15 Questions

**Score:** 12/15 correct = ready for Part 49.

**Question 1:** What is the minimum quorum needed for a 3-node cluster?
- A) 1
- B) 2
- C) 3
- D) 4

**Question 2:** What is the primary purpose of STONITH?
- A) Monitor cluster performance
- B) Forcefully remove a malfunctioning node
- C) Balance network traffic
- D) Provide virtual IP addressing

**Question 3:** Which DRBD protocol provides synchronous replication?
- A) Protocol A
- B) Protocol B
- C) Protocol C
- D) Protocol D

**Question 4:** In VRRP, what multicast address is used for advertisements?
- A) 224.0.0.1
- B) 224.0.0.18
- C) 239.255.255.250
- D) 224.0.0.5

**Question 5:** What is the formula for quorum in a cluster?
- A) N/2
- B) N/2 + 1
- C) (N-1)/2
- D) N - 1

**Question 6:** Which two layers make up the core of a Linux HA cluster stack?
- A) Docker + Kubernetes
- B) Corosync + Pacemaker
- C) Keepalived + HAProxy
- D) DRBD + LVM

**Question 7:** In Pacemaker, what does `resource-stickiness=100` do?
- A) Prevents resources from starting
- B) Makes resources prefer their current node
- C) Forces resources to run on all nodes
- D) Limits resources to 100MB memory

**Question 8:** What is the `track_script` option in Keepalived used for?
- A) Log all VRRP packets
- B) Monitor a service and adjust priority
- C) Track network throughput
- D) Audit configuration changes

**Question 9:** What is split-brain in a cluster context?
- A) A hardware failure in the CPU
- B) Nodes operate independently believing the other is dead
- C) A network split that doubles throughput
- D) A database partitioning scheme

**Question 10:** Which resource agent would you use for a virtual IP in Pacemaker?
- A) ocf:heartbeat:nginx
- B) ocf:heartbeat:IPaddr2
- C) ocf:heartbeat:Filesystem
- D) stonith:fence_ipmilan

**Question 11:** What filesystem allows multiple nodes to read/write simultaneously?
- A) ext4
- B) XFS
- C) GFS2
- D) NTFS

**Question 12:** What is the purpose of fencing_topology in Pacemaker?
- A) Define network topology for Corosync
- B) Provide fallback fencing methods
- C) Configure load balancing
- D) Set up storage replication

**Question 13:** In DRBD dual-primary mode, which additional component is required?
- A) A load balancer
- B) A cluster filesystem (GFS2/OCFS2)
- C) A second network interface
- D) A quorum device

**Question 14:** What happens on a VRRP backup node when `3 × advert_int` passes without hearing from master?
- A) The backup shuts down
- B) The backup transitions to MASTER
- C) The backup sends an alert only
- D) The backup restarts keepalived

**Question 15:** What is the `no-quorum-policy=stop` behavior?
- A) Cluster continues without quorum
- B) All resources stop if quorum is lost
- C) The node with the most resources survives
- D) Quorum is recalculated every minute


**Answers:** 1-B, 2-B, 3-C, 4-B, 5-B, 6-B, 7-B, 8-B, 9-B, 10-B, 11-C, 12-B, 13-B, 14-B, 15-B





[← Previous](19-whats-coming-in-part-49.md) | [↑ Index](index.md) | [Next →](21-summary.md)
