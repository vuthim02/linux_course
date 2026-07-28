## 15 Hands-On Practices

### Practice 1: Install Puppet Server and Agent, Sign Certs

```bash
# MASTER (puppet.example.com)
wget -O /tmp/puppet-release.deb https://apt.puppet.com/puppet8-release-jammy.deb
dpkg -i /tmp/puppet-release.deb && apt-get update && apt-get install -y puppetserver
sed -i 's/-Xms2g -Xmx2g/-Xms512m -Xmx512m/' /etc/default/puppetserver
systemctl start puppetserver && systemctl enable puppetserver

# AGENT (web01.example.com)
wget -O /tmp/puppet-release.deb https://apt.puppet.com/puppet8-release-jammy.deb
dpkg -i /tmp/puppet-release.deb && apt-get update && apt-get install -y puppet-agent
echo -e "[main]\nserver = puppet.example.com\ncertname = web01.example.com" > /etc/puppetlabs/puppet/puppet.conf
puppet agent -t  # Generate CSR

# MASTER: sign, then AGENT: run again
puppetserver ca sign --certname web01.example.com && puppet agent -t
```

### Practice 2: Write Puppet Manifest to Install Nginx with Custom index.html

```puppet
node 'web01.example.com' {
  package { 'nginx': ensure => installed }
  service { 'nginx': ensure => running, enable => true, require => Package['nginx'] }
  file { '/var/www/html/index.html':
    content => '<h1>Managed by Puppet</h1><p>Host: <%= @facts["networking"]["hostname"] %></p>',
    mode    => '0644', owner => 'www-data', group => 'www-data',
  }
}
```

```bash
puppet agent -t && curl http://web01.example.com
```

### Practice 3: Create Module with Classes, Use Hiera

```puppet
# modules/motd/manifests/init.pp
class motd (String $message = 'Welcome', Array $admin_emails = []) {
  file { '/etc/motd':
    content => epp('motd/motd.epp', { 'message' => $message, 'hostname' => $facts['networking']['hostname'],
      'admin_emails' => $admin_emails, 'uptime' => $facts['system_uptime']['uptime_string'] }),
    mode    => '0644',
  }
}
```

```yaml
# data/nodes/web01.example.com.yaml
motd::message: "Web Server Node"
motd::admin_emails: [ops@example.com]
```

### Practice 4: Implement Roles and Profiles Pattern

```puppet
# site.pp
node 'web01.example.com' { role('web_server::standard') }

# roles/manifests/web_server/standard.pp
class role::web_server::standard {
  include profile::base; include profile::nginx; include profile::firewall
  include profile::monitoring::node_exporter
}

# profiles/manifests/base.pp
class profile::base (
  Array[String] $packets  = lookup('profile::base::packages'),
  Array[Hash]   $users    = lookup('profile::base::users'),
  Integer       $ssh_port = lookup('profile::base::ssh_port'),
) {
  $packets.each |$pkg| { package { $pkg: ensure => installed } }
  $users.each |$u| {
    user { $u['username']: ensure => present, uid => $u['uid'], groups => $u['groups'],
           managehome => true }
    $u['ssh_keys'].each |$i, $k| {
      ssh_authorized_key { "${u['username']}-${i}": user => $u['username'], type => $k[0], key => $k[1] }
    }
  }
  file_line { 'ssh-port': path => '/etc/ssh/sshd_config', line => "Port ${ssh_port}", match => '^#?Port ',
    notify => Service['ssh'] }
  service { 'ssh': ensure => running, enable => true }
}
```

### Practice 5: Install Salt Master and Minion, Accept Keys, Ping Test

```bash
# MASTER
apt-get install -y salt-master
echo -e "interface: 0.0.0.0\nauto_accept: False" > /etc/salt/master.d/local.conf
systemctl enable --now salt-master

# MINION
apt-get install -y salt-minion
echo -e "master: salt.example.com\nid: web01.example.com" > /etc/salt/minion.d/local.conf
systemctl enable --now salt-minion

# MASTER
salt-key -A
salt 'web01*' test.ping   # → True
```

### Practice 6: Write SLS to Manage Users and SSH Keys

**`/srv/salt/users/init.sls`**:
```yaml
{% for user, config in pillar.get('users', {}).items() %}
{{ user }}-user:
  user.present:
    - name: {{ user }}
    - uid: {{ config.uid }}
    - groups: {{ config.groups | join(', ') }}
    - home: /home/{{ user }}
    - createhome: true
{{ user }}-ssh-dir:
  file.directory:
    - name: /home/{{ user }}/.ssh
    - user: {{ user }}
    - mode: 700
    - require:
      - user: {{ user }}-user
{% for key in config.get('ssh_keys', []) %}
{{ user }}-ssh-{{ loop.index }}:
  ssh_auth.present:
    - name: {{ key }}
    - user: {{ user }}
    - require:
      - file: {{ user }}-ssh-dir
{% endfor %}
{% endfor %}
```

**`/srv/pillar/users.sls`**:
```yaml
users:
  alice: { uid: 1001, groups: sudo,www-data, ssh_keys: [ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...] }
  bob:   { uid: 1002, groups: www-data, ssh_keys: [ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...] }
```

```bash
salt 'web01*' state.apply users
```

### Practice 7: Use Pillars for Secrets and Grains for Targeting

```yaml
# /srv/pillar/secrets.sls
secrets:
  db: { password: "MCPVbR6xKzq2!mN9", connection: "postgresql://app:MCPVbR6xKzq2!mN9@db01:5432/myapp" }
```

```yaml
# /srv/salt/app/init.sls
db-config:
  file.managed:
    - name: /etc/myapp/database.yml
    - contents: |
        password: {{ pillar.get('secrets:db:password') }}
        host: db01
    - mode: 600
```

```bash
salt 'web01*' grains.setval role web_server
salt -C 'G@role:web_server and G@environment:prod' test.ping
```

### Practice 8: Create Salt Orchestration

**`/srv/salt/orch/rolling_update.sls`**:
```yaml
canary-group:
  salt.state:
    - tgt: 'G@canary:true'
    - tgt_type: compound
    - sls: apex.update
    - batch: 1
    - fail_hard: true
main-fleet:
  salt.state:
    - tgt: 'web* and not G@canary:true'
    - tgt_type: compound
    - sls: apex.update
    - require:
      - salt: canary-group
    - batch: 5
```

```bash
salt-run state.orchestrate orch.rolling_update
```

### Practice 9: Install Chef Server and Workstation, Bootstrap a Node

```bash
# SERVER
dpkg -i chef-server-core_15.10.0-1_amd64.deb && chef-server-ctl reconfigure
chef-server-ctl user-create admin Admin User admin@example.com 'P@ssw0rd!' --filename /root/admin.pem
chef-server-ctl org-create myorg 'My Org' --association_user admin --filename /root/myorg-validator.pem

# WORKSTATION
dpkg -i chef-workstation_23.12.1055-1_amd64.deb
cat > ~/.chef/knife.rb << 'EOF'
node_name 'admin'
client_key '/root/admin.pem'
chef_server_url 'https://chef.example.com/organizations/myorg'
cookbook_path ['/root/cookbooks']
EOF

# BOOTSTRAP
knife bootstrap 10.0.0.5 --ssh-user ubuntu --sudo --node-name web01 --run-list 'role[web_server]'
```

### Practice 10: Write Chef Cookbook for Apache with Template

```ruby
# cookbooks/apache/recipes/default.rb
case node['platform_family']
when 'debian' then (pkg='apache2'; svc='apache2'; conf='/etc/apache2')
when 'rhel'   then (pkg='httpd';   svc='httpd';   conf='/etc/httpd')
end

package pkg { action :install }

template "#{conf}/ports.conf" do
  source 'ports.conf.erb'
  variables(listen_ports: node['apache']['listen_ports'] || [80, 443])
  notifies :restart, "service[#{svc}]"
end

service svc { action [:enable, :start]; supports reload: true }

node['apache']['modules'].each do |mod|
  execute "a2enmod #{mod}" do
    command "a2enmod #{mod}"
    not_if { File.exist?("/etc/apache2/mods-enabled/#{mod}.load") }
    notifies :restart, "service[#{svc}]"
  end
end

cookbook_file '/var/www/html/index.html' do
  source 'index.html'; owner 'www-data'; mode '0644'
end
```

```erb
<%# ports.conf.erb -%>
Listen <%= @listen_ports.join(' ') %>
NameVirtualHost *:80
```

### Practice 11: Use Encrypted Data Bags for Credentials

```bash
openssl rand -base64 512 > /root/encrypted_data_bag_secret
knife data bag create secrets --secret-file /root/encrypted_data_bag_secret
knife data bag from file secrets db.json --secret-file /root/encrypted_data_bag_secret
# db.json: { "id": "db", "password": "s3kr3t!", "host": "db01" }
```

```ruby
secret = Chef::EncryptedDataBagItem.load('secrets', 'db')
template '/etc/myapp/database.yml' do
  source 'database.yml.erb'
  sensitive true
  variables(password: secret['password'], host: secret['host'])
end
```

### Practice 12: Run Chef in Local Mode (Chef-Zero)

```bash
mkdir -p /tmp/chef-test/cookbooks/demo/recipes
cat > /tmp/chef-test/cookbooks/demo/recipes/default.rb << 'RUBY'
file '/tmp/chef-demo.txt' do
  content "Chef Zero test at #{Time.now}\nNode: #{node['fqdn']}"
  action :create
end
package 'nginx' { action :upgrade; notifies :restart, 'service[nginx]' }
service 'nginx' { action [:enable, :start] }
RUBY

chef-client --local-mode --run-list 'recipe[demo]' --cookbook-path /tmp/chef-test/cookbooks
chef-client --local-mode --run-list 'recipe[demo]' --cookbook-path /tmp/chef-test/cookbooks --json-attributes '{"demo":{"msg":"hello"}}'
```

### Practice 13: Compare Same Config in All Three Tools

**Puppet**:
```puppet
class profile::nginx_complete {
  user { 'webapp': ensure => present, uid => 2001, groups => ['www-data'], managehome => true }
  package { 'nginx': ensure => installed }
  file { '/etc/nginx/nginx.conf': content => template('profile/nginx.conf.erb'), require => Package['nginx'] }
  service { 'nginx': ensure => running, enable => true, subscribe => File['/etc/nginx/nginx.conf'] }
  package { 'ufw': ensure => installed }
  exec { 'allow-nginx': command => '/usr/sbin/ufw allow 80/tcp && /usr/sbin/ufw allow 443/tcp',
    unless => '/usr/sbin/ufw status | grep -q "80/tcp.*ALLOW"', require => Package['ufw'] }
}
```

**Salt**:
```yaml
webapp-user:
  user.present: [{ name: webapp, uid: 2001, groups: www-data, createhome: true }]
nginx-pkg:
  pkg.installed: [{ name: nginx }, { require: [{ user: webapp-user }] }]
nginx-conf:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://nginx_complete/files/nginx.conf
    - require:
      - pkg: nginx-pkg
nginx-service:
  service.running: [{ name: nginx, enable: true }, { watch: [{ file: nginx-conf }] }]
ufw-pkg: { pkg.installed: [{ name: ufw }] }
ufw-allow:
  cmd.run: [{ name: ufw allow 80/tcp && ufw allow 443/tcp },
    { unless: ufw status | grep -q "80/tcp.*ALLOW" }, { require: [{ pkg: ufw-pkg }] }]
```

**Chef**:
```ruby
user 'webapp' { uid 2001; groups ['www-data']; manage_home true; action :create }
package 'nginx' { action :install }
template '/etc/nginx/nginx.conf' { source 'nginx.conf.erb'; notifies :reload, 'service[nginx]' }
service 'nginx' { action [:enable, :start]; supports reload: true }
package 'ufw' { action :install }
execute 'ufw-allow-nginx' { command 'ufw allow 80/tcp && ufw allow 443/tcp'
  not_if 'ufw status | grep -q "80/tcp.*ALLOW"' }
```

**Ansible** (for comparison):
```yaml
- name: Configure web server
  hosts: all; become: true
  tasks:
    - user: { name: webapp, uid: 2001, groups: www-data, create_home: true }
    - apt:  { name: nginx, state: present }
    - template: { src: nginx.conf.j2, dest: /etc/nginx/nginx.conf }
      notify: reload nginx
    - service: { name: nginx, state: started, enabled: true }
    - ufw: { rule: allow, port: '{{ item }}', proto: tcp }
      loop: [80, 443]
  handlers:
    - name: reload nginx
      service: { name: nginx, state: reloaded }
```

### Practice 14: Use Test-Kitchen to Test on Multiple Platforms

```bash
chef generate cookbook myapp && cd myapp
```

**`kitchen.yml`**:
```yaml
driver: { name: vagrant }
provisioner: { name: chef_zero }
platforms:
  - name: ubuntu-22.04
  - name: ubuntu-20.04
  - name: centos-stream-9
suites:
  - name: default
    run_list: ["recipe[myapp::default]"]
```

```ruby
# test/integration/default/default_test.rb
control 'myapp-01' do
  describe package('myapp')   { it { should be_installed } }
  describe service('myapp')   { it { should be_running } }
  describe port(8080)         { it { should be_listening } }
end
```

```bash
kitchen test   # converge + verify + destroy on all platforms
```

### Practice 15: Real-World Integration — CM Strategy for 500 Servers

**Scenario**: Fintech with 500 servers across 3 DCs + AWS (200 web, 100 API, 50 DB, 50 cache, 50 MQ, 50 monitoring). PCI-DSS and SOC2 compliance. 6 SREs. Hybrid: 300 on-prem + 200 AWS.

**Recommended: Puppet Enterprise**

**Why**:
1. **Scale**: Handles 500 nodes easily (PE supports 10K+)
2. **Compliance**: Built-in reporting + PuppetDB = audit-ready history
3. **Data separation**: Hiera + hiera-eyaml for clear separation of global, env, node, and secret data
4. **Roles/Profiles**: Clean architecture for 8 server types
5. **PuppetDB search**: Query which nodes have specific package versions
6. **RBAC**: Enterprise console for team access control

**Architecture**:
```
Control Repo (GitLab) → r10k deploy → Puppet Enterprise
  3x Compile Masters (LB) + PuppetDB HA (Patroni)
  → Agents: 150 DC1 + 150 DC2 + 200 AWS
```

**Management Plan**:
- **Control repo**: `main` (prod), `staging`, `dev` branches. Puppetfile for modules.
- **Node classification**: Hiera-based (role + env keys). All nodes get `role::base`.
- **Change management**: MR → review → merge → webhook triggers r10k → staggered agent runs (5% canary → full).
- **Compliance**: CIS benchmarks via `puppetlabs/cis_benchmark`. All changes in PuppetDB.
- **HA**: 3 compile masters behind HAProxy. PuppetDB with Patroni PostgreSQL HA.
- **Migration to containers**: Phase 1 — Puppet manages base OS + Docker. Phase 2 — stateless apps to K8s. Phase 3 — Puppet only for stateful DBs + compliance.





[← Previous](13-13-modern-era.md) | [↑ Index](index.md) | [Next →](15-deep-understanding.md)
