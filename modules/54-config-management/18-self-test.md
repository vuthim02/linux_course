## Self-Test

1. What is the difference between declarative and procedural configuration management? Give one example of each.

2. Explain the resource abstraction layer in Puppet. How does `package { 'nginx': ensure => installed }` work differently on Ubuntu vs CentOS without changing the manifest?

3. Write a Puppet manifest that installs nginx, ensures the service is running, and deploys `/etc/nginx/nginx.conf` from an ERB template with `worker_processes = 4`. Include proper dependency ordering.

4. What is Hiera and how does it achieve data separation in Puppet? Write a `hiera.yaml` hierarchy with common, per-OS, and per-node data files.

5. In SaltStack, what is the difference between grains and pillars? When would you use each?

6. Write a Salt SLS file that creates user `deploy` (UID 2001), adds their SSH key, installs nginx, and ensures the service is running. Use `require` for ordering.

7. What is Salt's event bus and how does the reactor system work? Give an example of a reactor rule responding to a minion startup.

8. How does Chef's Search API work? Write a Ruby snippet using `search` to find all nodes with role `web_server` and generate nginx upstream configs for them.

9. Write a Chef recipe that: creates user `webapp` (UID 2001), installs nginx, deploys `/etc/nginx/nginx.conf` from template, enables/starts the service, and notifies on template changes.

10. What are the advantages and disadvantages of agentless (Ansible) vs agent-based (Puppet/Chef/Salt) configuration management?

11. Explain the Puppet catalog compilation process from facts submission to report delivery.

12. What is the roles and profiles pattern in Puppet? Why is it considered a best practice for large deployments?

13. Compare testing ecosystems: rspec-puppet vs test-kitchen/ChefSpec vs Salt's testing vs molecule. Which would you choose for a team of 6 SREs managing 500 servers?

14. Design a simple CM strategy for 50 servers (10 web, 5 DB, 5 cache, rest mixed). Choose a tool and justify based on architecture, team skills, and ops requirements.

15. How does the shift toward containers and immutable infrastructure affect traditional CM tools? What use cases remain where CM is still the best solution?

**Score:** 12/15 correct = ready for Part 55.

---

*Linux SysAdmin Course | Part 54 of ∞ | Reverse Engineering Approach*
*Previous → Part 53: CI/CD Pipelines*
*Next → Part 55: Immutable Infrastructure*

[← Previous](part53.md) | [Next →](part55.md)


---

[← Previous](17-whats-coming-in-part-55.md) | [↑ Index](index.md)
