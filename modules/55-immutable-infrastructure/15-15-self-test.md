## 15. Self-Test

**15 questions. Score 12/15 correct = ready for Part 56.**

1. **What is the fundamental difference between mutable and immutable infrastructure?**
   - A) Mutable uses VMs, immutable uses containers
   - B) Mutable modifies instances in place; immutable replaces instances
   - C) Mutable is cheaper; immutable is more expensive
   - D) Mutable uses Linux; immutable uses Windows

2. **What does Packer do?**
   - A) Orchestrates containers across clusters
   - B) Creates identical machine images for multiple platforms
   - C) Manages cloud resources declaratively
   - D) Monitors infrastructure metrics

3. **Which file format does Packer use for templates?**
   - A) JSON
   - B) YAML
   - C) HCL2 (.pkr.hcl)
   - D) TOML

4. **What is the purpose of a provisioner in Packer?**
   - A) To create the source instance
   - B) To configure the instance during build
   - C) To package the final artifact
   - D) To authenticate with cloud providers

5. **Which builder would you use to create an AMI in AWS?**
   - A) `googlecompute`
   - B) `azure-arm`
   - C) `amazon-ebs`
   - D) `qemu`

6. **Why should SSH keys never be baked into a golden image?**
   - A) They expire too quickly
   - B) Every instance would have the same host key
   - C) They take up too much space
   - D) SSH should use passwords instead

7. **What is the role of cloud-init on first boot?**
   - A) To install the operating system
   - B) To run userdata scripts and configure the instance
   - C) To create the golden image
   - D) To terminate unused instances

8. **How does Packer create an AMI?**
   - A) By modifying the source AMI directly
   - B) By starting an instance, provisioning it, taking an EBS snapshot, and registering it
   - C) By copying the instance's root filesystem to an S3 bucket
   - D) By running a Dockerfile on the build host

9. **What is the "bake vs fry" concept?**
   - A) Bake = everything in image vs fry = heavy post-boot config
   - B) Bake = Docker vs fry = VM
   - C) Bake = dev vs fry = prod
   - D) Bake = AWS vs fry = Azure

10. **What is the recommended strategy for handling database state in immutable infrastructure?**
    - A) Store databases on the instance's EBS volume
    - B) Use external managed databases (RDS, Aurora)
    - C) Bake the database into the image
    - D) Use SQLite on ephemeral storage

11. **Which of the following should be cleaned up before finalizing an image?**
    - A) The application source code
    - B) SSH host keys and authorized_keys
    - C) The nginx binary
    - D) The /etc/hosts file

12. **What is the purpose of the `-debug` flag in `packer build`?**
    - A) To log verbose output
    - B) To pause between steps and allow SSH inspection
    - C) To run builds in parallel
    - D) To disable cleanup of the build instance

13. **How are images versioned in a production pipeline?**
    - A) Only by timestamp
    - B) By semantic version, commit hash, and/or timestamp
    - C) Random UUID
    - D) By the base AMI ID

14. **What is a blue/green deployment?**
    - A) Deploying to blue servers, then green servers
    - B) Running two environments (blue and green) and switching traffic between them
    - C) Deploying to the same instances with a different color label
    - D) Deploying to one region, then another

15. **Why do immutable deployments close SSH access to production?**
    - A) To save on licensing costs
    - B) To reduce attack surface and enforce changes through the pipeline
    - C) Because SSH is not supported on cloud instances
    - D) To make debugging more challenging

**Answer Key:**
1. B  2. B  3. C  4. B  5. C  6. B  7. B  8. B  9. A  10. B  11. B  12. B  13. B  14. B  15. B

**Score:** ____ / 15

---



---

[← Previous](14-14-command-reference.md) | [↑ Index](index.md) | [Next →](16-whats-coming-in-part-56.md)
