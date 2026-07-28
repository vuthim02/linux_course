## 🧠 Deep Understanding — How Cloud Infrastructure Really Works

### How Cloud Hypervisors Differ from Traditional Virtualization

**AWS Nitro System:**
```
Traditional Virtualization:
┌──────────────────────────────┐
│  Virtual Machine              │
│  ├── Guest OS                 │
│  ├── Virtual Devices (emulated)│
│  └── Hypervisor (Xen/KVM)    │
│        ├── CPU scheduler      │
│        ├── Memory manager     │
│        └── Device emulation   │
└──────────────────────────────┘
  → All I/O goes through hypervisor (overhead)

AWS Nitro:
┌──────────────────────────────┐
│  Virtual Machine              │
│  ├── Guest OS                 │
│  └── Nitro Drivers (paravirt) │
├──────────────────────────────┤
│  Nitro Hypervisor (KVM-based) │
│  ├── CPU/Memory only          │
│  └── No device emulation      │
├──────────────────────────────┤
│  Nitro Cards (hardware):      │
│  ├── Nitro EBS (storage)      │
│  ├── Nitro ENIC (networking)  │
│  └── Nitro TPM (security)     │
└──────────────────────────────┘
  → I/O is offloaded to dedicated hardware
  → Near bare-metal performance
  → Each Nitro card has its own CPU
```

**GCP KVM (Google's custom KVM):**
- GCP uses a highly modified KVM hypervisor
- Custom networking stack in the hypervisor (gVNIC, Andromeda)
- No traditional host OS — hypervisor is minimal
- Live migration is transparent (VM moves while running)
- Nested virtualization supported natively

**Azure Hyper-V:**
- Microsoft's own Type 1 hypervisor
- Root partition (Parent) manages child partitions
- VMBus is the communication channel between partitions
- Host OS is a stripped-down Windows Server
- Supports nested virtualization for containers

### How Cloud Networking Is Implemented at Scale

**VXLAN Overlay Networks:**
```
Physical Network (Underlay):
┌──────┐    ┌──────┐    ┌──────┐
│ Spine│────│ Spine│────│ Spine│
└──┬───┘    └──┬───┘    └──┬───┘
   │           │           │
┌──┴───┐    ┌──┴───┐    ┌──┴───┐
│ Leaf │    │ Leaf │    │ Leaf │
└──┬───┘    └──┬───┘    └──┬───┘
   │           │           │
 ┌─┴─┐       ┌─┴─┐       ┌─┴─┐
 │Host│      │Host│      │Host│
 └───┘       └───┘       └───┘

Virtual Network (Overlay):
  VM-A (10.0.1.5) ── VXLAN Tunnel ── VM-B (10.0.2.10)
       │                                    │
  VTEP (VXLAN Tunnel Endpoint)         VTEP
       │                                    │
  ┌────┴────┐                         ┌────┴────┐
  │  VNI 42 │  ← Encapsulated in UDP  │  VNI 42 │
  └─────────┘   Outer: Host IPs       └─────────┘
```

**VXLAN frame structure:**
```
┌──────────────────────────────────────────────────────────┐
│ Outer MAC │ Outer IP │ Outer UDP │ VXLAN │ Inner MAC/IP │
│ (14 bytes)│ (20 bytes)│ (8 bytes)│ (8 bytes)│ (original) │
└──────────────────────────────────────────────────────────┘
```

**Distributed Firewalls:**
- AWS Security Groups are NOT running on a physical appliance
- They are implemented in the Nitro ENIC card
- Rules are evaluated at line rate in hardware
- Every packet is checked; there's no bottleneck
- This is why SGs scale to thousands of rules without performance impact

**AWS Hyperplane (NAT Gateway, ALB, NLB):**
- Not a VM — it's a distributed data plane
- Runs on dedicated Nitro hardware
- Multi-tenant, multi-availability zone
- Scales to 100 Gbps automatically

### How IAM Authorization Works

**Policy Evaluation Engine:**
```
Request arrives with:
┌─────────────────────────────────┐
│ Principal: user/alice           │
│ Action:    ec2:RunInstances     │
│ Resource:  arn:aws:ec2:.../*   │
│ Context:   IP=203.0.113.5      │
│           Time=2024-06-15T10:00│
│           MFA=true              │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 1. AUTHENTICATION CHECK         │
│    Is the principal who they    │
│    claim to be? (cryptographic) │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 2. POLICY AGGREGATION           │
│    Collect ALL applicable       │
│    policies:                    │
│    - Identity-based (user/group)│
│    - Resource-based (bucket)    │
│    - Organizations SCP          │
│    - Session policies (STS)     │
│    - Permissions boundary       │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 3. DENY EVALUATION              │
│    Any explicit DENY? → DENIED  │
│    (SCPs, boundary, identity)   │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 4. ALLOW EVALUATION             │
│    Any explicit ALLOW? → ALLOWED│
│    (identity or resource policy)│
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 5. DEFAULT → DENY (implicit)    │
│    No explicit allow = denied   │
└─────────────────────────────────┘
```

**Condition Keys:**
```json
{
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "*",
    "Condition": {
        "IpAddress": {
            "aws:SourceIp": "203.0.113.0/24"
        },
        "Bool": {
            "aws:SecureTransport": "true"
        },
        "DateGreaterThan": {
            "aws:CurrentTime": "2024-01-01T00:00:00Z"
        },
        "StringEquals": {
            "aws:RequestedRegion": ["us-east-1", "eu-west-1"]
        }
    }
}
```

**GCP IAM Authorization:**
```
1. Policy is attached to the RESOURCE (not the user)
2. Hierarchy inheritance: Organization → Folder → Project → Resource
3. Bindings are evaluated: member + role = set of permissions
4. Deny policies (available in GCP) override allow
5. Conditions use CEL (Common Expression Language):
   - condition: "resource.name.startsWith('projects/my-project/zones/us-central1-a/instances/web-')"
```

**Azure RBAC Authorization:**
```
1. Scope hierarchy: Management Group → Subscription → Resource Group → Resource
2. Role definition includes Actions, NotActions, DataActions
3. Assignments are additive (inherited from parent scope)
4. Deny assignments (explicit) override role assignments
5. Azure Policy (different from RBAC) enforces compliance rules
```

### How Cloud Storage Is Replicated

**Cross-Region Replication (CRR):**
```
AWS S3 CRR:
  us-east-1                  eu-west-1
┌──────────────┐    async   ┌──────────────┐
│ Bucket A      │───────────│ Bucket B      │
│ ├─ obj v1     │  S3 event │ ├─ obj v1     │
│ ├─ obj v2     │  triggers │ ├─ obj v2     │
│ └─ obj v3     │  PUT copy │ └─ obj v3     │
└──────────────┘            └──────────────┘
  → S3 replicates within 15 minutes typically
  → Replication time = object size / bandwidth
  → Each version is replicated separately
```

**Storage Classes Across Clouds:**

| AWS | GCP | Azure | Durability | Min Storage | Retrieval |
|-----|-----|-------|------------|-------------|-----------|
| S3 Standard | Standard | Hot | 99.999999999% | None | Instant |
| S3 Standard-IA | Nearline | Cool | 99.999999999% | 30 days | Instant |
| S3 One Zone-IA | - | - | 99.999999999% | 30 days | Instant |
| S3 Glacier | Coldline | Cold | 99.999999999% | 90 days | 1-5 min |
| S3 Glacier Deep Archive | Archive | Archive | 99.999999999% | 180 days | 12 hours |

**Erasure Coding vs Replication:**
```
Replication (Traditional):
  ┌─────┐   ┌─────┐   ┌─────┐
  │ Obj │   │ Obj │   │ Obj │
  └─────┘   └─────┘   └─────┘
  Disk 1    Disk 2    Disk 3
  → 3x storage cost, can lose 2 disks
  → Simple, works with any data

Erasure Coding (Cloud):
  ┌─────┬──┬──┬──┬──┬──┐
  │ d1  │d2│d3│p1│p2│p3│  ← 6 data + 3 parity shards
  └─────┴──┴──┴──┴──┴──┘
  Disk 1 2  3  4  5  6
  → 1.5x storage cost, can lose 3 disks
  → More efficient than replication
  → Used in: S3, GCS, Azure Blob
  → Reed-Solomon encoding: any k of n shards reconstruct the data

GCS uses 16 data + 3 parity shards by default (11x9s durability)
S3 uses 11x9s durability across multiple devices
Azure LRS = 3 replicas within a single datacenter (LRS)
Azure GRS = 3 replicas + 3 replicas in paired region
```





[← Previous](13-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](15-complete-command-reference-equivalent-commands.md)
