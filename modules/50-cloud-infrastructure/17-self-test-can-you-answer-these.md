## 📝 Self-Test — Can You Answer These?

1. What is the difference between IaaS, PaaS, and SaaS? Give an example of each from AWS.
2. What is an Availability Zone and how does it differ from a Region?
3. What command configures the AWS CLI with your credentials? Where are they stored?
4. How do you retrieve temporary credentials from an EC2 instance that has an IAM role?
5. What is the difference between `aws s3 cp` and `aws s3 sync`?
6. In AWS VPC, what is the difference between a Security Group and a NACL?
7. What does a NAT Gateway do and why would you put a NAT Gateway in a public subnet?
8. What is the GCP equivalent of AWS EC2? What is the Azure equivalent?
9. How do you pass a startup script to an EC2 instance? To a GCE instance? To an Azure VM?
10. What is a SAS token in Azure and how does it differ from a storage account key?
11. How does AWS IAM role trust policy work? What is the `Principal` field?
12. What is the difference between AWS IAM roles and GCP service accounts?
13. How do you connect to a private EC2 instance that has no public IP and no SSH key?
14. What is the difference between AWS S3 Standard-IA, S3 Glacier, and S3 Glacier Deep Archive?
15. What strategies can you use to reduce cloud costs across all three providers?

**Score:** 12/15 correct = ready for Part 51.


## Answer Key

### Q1: What is the difference between IaaS, PaaS, and SaaS?
**Answer:** IaaS = virtual machines/storage/networking (EC2). PaaS = managed platform for apps (Elastic Beanstalk, App Engine). SaaS = ready-to-use software (Gmail, Office 365).

### Q2: What is an Availability Zone vs a Region?
**Answer:** A Region = geographic area with multiple AZs. An AZ = isolated data center(s) within a Region, with independent power/network.

### Q3: What command configures AWS CLI credentials?
**Answer:** `aws configure` — stores credentials in `~/.aws/credentials` and config in `~/.aws/config`.

### Q4: How do you retrieve temporary credentials from an EC2 instance with an IAM role?
**Answer:** Instance Metadata Service: `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/role-name` returns temporary credentials.

### Q5: What is the difference between `aws s3 cp` and `aws s3 sync`?
**Answer:** `cp` copies files. `sync` copies only new/modified files and optionally deletes extra files at the destination.

### Q6: What is the difference between Security Groups and NACLs?
**Answer:** Security Groups = stateful, instance-level firewall (allow rules only). NACLs = stateless, subnet-level firewall (allow + deny rules).

### Q7: What does a NAT Gateway do?
**Answer:** Allows private subnet instances to access the internet for outbound traffic while remaining unreachable from the internet directly.

### Q8: What are the GCP and Azure equivalents of EC2?
**Answer:** GCP: Compute Engine (GCE). Azure: Virtual Machines.

### Q9: How do you pass startup scripts to cloud instances?
**Answer:** AWS: User Data. GCE: metadata startup-script. Azure: Custom Script Extension or cloud-init.

### Q10: What is a SAS token vs a storage account key?
**Answer:** SAS (Shared Access Signature) is a time-limited, scoped token with specific permissions. Storage account key = full access (never share).

### Q11: How does IAM role trust policy work?
**Answer:** The `Principal` field specifies who can assume the role (e.g., `ec2.amazonaws.com`). The role grants temporary credentials to that principal.

### Q12: What is the difference between IAM roles and GCP service accounts?
**Answer:** IAM roles are identity-based policies. GCP service accounts are bot accounts with their own credentials, attached to resources.

### Q13: How do you connect to a private EC2 instance with no public IP?
**Answer:** Use SSM Session Manager (no SSH needed), or connect via a bastion host, or use EC2 Instance Connect.

### Q14: S3 Standard-IA vs Glacier vs Glacier Deep Archive?
**Answer:** Standard-IA: infrequent access, millisecond retrieval. Glacier: archival, minutes-hours retrieval. Deep Archive: long-term, 12+ hours retrieval, cheapest.

### Q15: Strategies to reduce cloud costs?
**Answer:** Reserved instances/Savings Plans, spot instances, right-sizing, auto-scaling, S3 lifecycle policies, deleting unused resources, using ARM instances.


*Linux SysAdmin Course | Part 50 of ∞ | Reverse Engineering Approach*
*Previous → Part 49: Security Hardening and Auditing*
*Next → Part 51: Infrastructure as Code — Terraform*

[← Previous](part49.md) | [Next →](part51.md)



[← Previous](16-whats-coming-in-part-51.md) | [↑ Index](index.md)
