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
## Answer Key
### Q1: What is the difference between declarative and procedural CM?
**Answer:** Declarative = describe desired state, tool figures out steps (Puppet, Ansible). Procedural = write explicit steps (Bash scripts).
### Q2: How does Puppet's resource abstraction work?
**Answer:** Puppet translates `package { 'nginx': ensure => installed }` to the correct command (`apt` on Debian, `dnf` on RHEL) using providers.
### Q3: Puppet manifest for nginx with dependency ordering.
**Answer:**
```puppet
package { 'nginx': ensure => installed }
file { '/etc/nginx/nginx.conf':
  ensure  => file,
  content => template('mymodule/nginx.conf.erb'),
  require => Package['nginx'],
}
service { 'nginx':
  ensure    => running,
  subscribe => File['/etc/nginx/nginx.conf'],
}
```
### Q4: What is Hiera and how does it achieve data separation?
**Answer:** Hiera is Puppet's hierarchical data lookup system. It merges data from common → OS → node-specific files. Config in `hiera.yaml`.
### Q5: Grains vs pillars in SaltStack?
**Answer:** Grains = static system properties (OS, CPU, memory). Pillars = server-side data specific to minions (passwords, configs). Grains are local; pillars are assigned.
### Q6: Salt SLS for user deploy with SSH key and nginx.
**Answer:**
```yaml
deploy_user:
  user.present:
    - uid: 2001
    - home: /home/deploy
deploy_ssh_key:
  ssh_auth.present:
    - user: deploy
    - name: ssh-rsa AAAA...
nginx:
  pkg.installed
  service.running:
    - require:
      - pkg: nginx
```
### Q7: Salt event bus and reactor system?
**Answer:** Event bus publishes tagged events (salt/auth, salt/minion/start). Reactors match events to reactions (SLS files). E.g., react to minion startup by assigning a role.
### Q8: Chef Search API for nginx upstreams?
**Answer:**
```ruby
web_servers = search(:node, 'role:web_server')
template '/etc/nginx/upstream.conf' do
  variables servers: web_servers.map { |n| n['ipaddress'] }
end
```
### Q9: Chef recipe for webapp user and nginx.
**Answer:**
```ruby
user 'webapp' do
  uid 2001
end
package 'nginx'
template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  notifies :restart, 'service[nginx]'
end
service 'nginx' do
  action [:enable, :start]
end
```
### Q10: Agentless vs agent-based CM?
**Answer:** Agentless (Ansible): simpler, no daemon, SSH-based, slower. Agent-based (Puppet/Chef/Salt): faster, more features, continuous enforcement, but requires agent on every node.
### Q11: Puppet catalog compilation process?
**Answer:** Facts submitted → Parser compiles manifest to AST → Compiler creates catalog (resource graph) → Catalog sent to agent → Agent applies catalog → Report sent to server.
### Q12: Roles and profiles pattern in Puppet?
**Answer:** Profiles encapsulate layers (profile::web, profile::db). Roles combine profiles for a server type (role::webserver). Reusable, maintainable, testable.
### Q13: Testing ecosystems comparison?
**Answer:** rspec-puppet (unit tests for Puppet), test-kitchen (integration with VMs), Molecule (Ansible testing). For 6 SREs/500 servers: Ansible + Molecule for simplicity, or Puppet + rspec-puppet for scale.
### Q14: CM strategy for 50 servers?
**Answer:** Ansible for agentless simplicity. Group by role (web, DB, cache). Use roles + Ansible Vault for secrets. AWX/Tower for UI and scheduling. Git for version control.
### Q15: How do containers/immutable infra affect CM?
**Answer:** CM shifts left into image building (Packer + Ansible). Runtime CM is less needed but still valuable for: configuration drift, security patches on VMs, and legacy systems.
*Linux SysAdmin Course | Part 54 of ∞ | Reverse Engineering Approach*
*Previous → Part 53: CI/CD Pipelines*
*Next → Part 55: Immutable Infrastructure*
[← Previous](17-whats-coming-in-part-55.md) | [↑ Index](index.md)
