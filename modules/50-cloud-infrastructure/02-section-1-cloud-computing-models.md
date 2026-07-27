## 🔍 Section 1: Cloud Computing Models

### IaaS vs PaaS vs SaaS

```
┌─────────────────────────────────────────────────────────┐
│                   YOU MANAGE            PROVIDER MANAGES │
├─────────────────────────────────────────────────────────┤
│ IaaS  │ Applications Data Runtime OS │ Virtualization   │
│       │ Middleware Container          │ Servers Storage  │
│       │                              │ Networking       │
├─────────────────────────────────────────────────────────┤
│ PaaS  │ Applications Data            │ Runtime OS       │
│       │                              │ Middleware       │
│       │                              │ Virtualization   │
│       │                              │ Servers Storage  │
│       │                              │ Networking       │
├─────────────────────────────────────────────────────────┤
│ SaaS  │                            │ Everything        │
│       │                            │ (you just use it) │
└─────────────────────────────────────────────────────────┘
```

**IaaS (Infrastructure as a Service):** You get virtualized hardware — CPU, RAM, storage, networking. You manage the OS, middleware, runtime, and apps. AWS EC2, GCP Compute Engine, Azure VMs.

**PaaS (Platform as a Service):** You deploy code without managing the underlying infrastructure. AWS Elastic Beanstalk, GCP App Engine, Azure App Services.

**SaaS (Software as a Service):** Ready-to-use software. AWS WorkMail, GCP Workspace, Microsoft 365.

### Deployment Models

| Model | Description | Example Use |
|-------|-------------|-------------|
| Public Cloud | Shared infrastructure over internet | AWS, GCP, Azure |
| Private Cloud | Dedicated to one organization | OpenStack, VMware on-prem |
| Hybrid Cloud | Mix of public and private | Bursting, data residency |
| Multi-Cloud | Using multiple public clouds | Redundancy, best-of-breed |

### OPEX vs CAPEX

```
CAPEX (Traditional):
  Buy servers:    $50,000 upfront
  Rack space:     $2,000/month
  Cooling/Power:  $1,500/month
  Staff:          $10,000/month
  → You pay whether you use it or not

OPEX (Cloud):
  Per hour:       $0.50 for an instance
  Per GB:         $0.023 for storage
  Per request:    $0.0000004 per API call
  → You pay only for what you use
```

### Regions and Availability Zones

```
Region (us-east-1)
├── Availability Zone us-east-1a
│   ├── Data center cluster 1
│   └── Data center cluster 2
├── Availability Zone us-east-1b
│   ├── Data center cluster 3
│   └── Data center cluster 4
└── Availability Zone us-east-1c
    ├── Data center cluster 5
    └── Data center cluster 6
```

**Region:** Geographic area with 2+ availability zones. AWS: us-east-1, eu-west-2, ap-southeast-1. GCP: us-central1, europe-west1, asia-east1. Azure: eastus, westeurope, southeastasia.

**Availability Zone (AZ):** Isolated data center within a region. Each AZ has independent power, cooling, networking. AZs are connected by low-latency fiber.

**Global vs Regional vs Zonal resources:**
- **Global:** IAM users, CloudFront CDN, DNS (Route 53)
- **Regional:** VPC, S3 buckets, security groups
- **Zonal:** EC2 instances, EBS volumes (tied to one AZ)

```bash
# List AWS regions
aws ec2 describe-regions

# List GCP regions
gcloud compute regions list

# List Azure regions
az account list-locations -o table
```

---



---

[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-aws-cli.md)
