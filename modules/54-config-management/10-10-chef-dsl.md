## 10. Chef DSL

### Resources

```ruby
package 'nginx' do
  version '1.24.0'
  action :install
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    worker_processes: node['nginx']['worker_processes'],
    worker_connections: node['nginx']['worker_connections'],
  )
  notifies :reload, 'service[nginx]'
end

service 'nginx' do
  supports reload: true, restart: true, status: true
  action [:enable, :start]
end

user 'webapp' do
  uid 2001
  gid 'www-data'
  home '/home/webapp'
  manage_home true
  action :create
end

execute 'reload-systemd' do
  command 'systemctl daemon-reload'
  action :nothing
  subscribes :run, 'template[/etc/systemd/system/webapp.service]'
end

directory '/opt/myapp' do
  owner 'webapp'
  group 'www-data'
  mode '0755'
  recursive true
end

cookbook_file '/etc/nginx/default.conf' do
  source 'default.conf'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :reload, 'service[nginx]'
end

cron 'rotate-logs' do
  command '/usr/local/bin/rotate-logs'
  user 'root'
  hour 3
  minute 0
end
```

### Recipes

```ruby
# recipes/default.rb
include_recipe 'nginx::install'
include_recipe 'nginx::config'
include_recipe 'nginx::service'

# recipes/install.rb
package 'nginx' do
  action :install
end
case node['platform_family']
when 'debian' then include_recipe 'nginx::install_debian'
when 'rhel'   then include_recipe 'nginx::install_rhel'
end

# recipes/config.rb
template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  variables(
    worker_processes: node['nginx']['worker_processes'] || 'auto',
    worker_connections: node['nginx']['worker_connections'] || 1024,
    gzip: node['nginx']['gzip'] || true,
  )
  notifies :reload, 'service[nginx]'
end

# Dynamic config from search
search(:node, "role:web_server AND chef_environment:#{node.chef_environment}").each do |n|
  template "/etc/nginx/conf.d/#{n['fqdn']}.conf" do
    source 'upstream.conf.erb'
    variables(backend_host: n['ipaddress'], backend_port: n['nginx']['port'] || 8080)
    notifies :reload, 'service[nginx]'
  end
end
```

### Attributes

**`attributes/default.rb`**:
```ruby
default['nginx']['worker_processes'] = 'auto'
default['nginx']['worker_connections'] = 1024
default['nginx']['gzip'] = true
```

**Precedence** (lowest → highest): `default` → `force_default` → `normal` → `override` → `force_override` → `automatic` (Ohai, cannot be overridden).

### Templates (ERB)

**`templates/default/nginx.conf.erb`**:
```nginx
# Managed by Chef
user <%= @user || 'www-data' %>;
worker_processes <%= @worker_processes %>;
events { worker_connections <%= @worker_connections %>; }
http {
  include /etc/nginx/mime.types;
  <% if @gzip %>gzip on; gzip_types text/plain text/css; <% end %>
  include /etc/nginx/conf.d/*.conf;
}
```

### Data Bags

```bash
knife data bag create users
```

```json
// data_bags/users/alice.json
{ "id": "alice", "uid": 1001, "groups": ["sudo","www-data"],
  "ssh_keys": ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..."] }
```

```ruby
# Use in recipe
search(:users, '*:*').each do |u|
  user u['id'] { uid u['uid']; groups u['groups']; manage_home true; action :create }
  u['ssh_keys'].each_with_index do |key, i|
    file "/home/#{u['id']}/.ssh/authorized_keys" do
      content "#{key}\n"; mode '0600'; owner u['id']
    end
  end
end
```

### Encrypted Data Bags

```bash
openssl rand -base64 512 > secret.key
knife data bag create passwords --secret-file secret.key
knife data bag from file passwords db.json --secret-file secret.key
# db.json: { "id": "db", "password": "SuperS3kr3t!", "host": "db01" }
```

```ruby
secret = Chef::EncryptedDataBagItem.load('passwords', 'db')
template '/etc/myapp/database.yml' do
  source 'database.yml.erb'
  sensitive true
  variables(password: secret['password'], host: secret['host'])
end
```

### Roles and Environments

**`roles/web_server.json`**:
```json
{
  "name": "web_server",
  "run_list": ["recipe[base]", "recipe[nginx]", "recipe[firewall]"],
  "default_attributes": { "nginx": { "worker_processes": 4 } }
}
```

**`environments/production.json`**:
```json
{
  "name": "production",
  "cookbook_versions": { "nginx": "~> 5.0" },
  "override_attributes": { "nginx": { "worker_processes": 8 } }
}
```

### Search API

```ruby
search(:node, 'platform:ubuntu')
search(:node, 'platform:ubuntu AND chef_environment:production')
search(:node, 'role:web_server OR role:api_server')
search(:node, 'fqdn:*.example.com')
search(:node, 'role:web_server', filter_result: { 'name' => ['name'], 'ip' => ['ipaddress'] })
```

Search queries Chef Server's Solr/ES index, updated after every chef-client run.





[← Previous](09-9-chef-architecture.md) | [↑ Index](index.md) | [Next →](11-11-chef-in-practice.md)
