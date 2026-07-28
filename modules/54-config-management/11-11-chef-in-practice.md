## 11. Chef in Practice

### Berksfile (Cookbook Dependencies)

```ruby
source 'https://supermarket.chef.io'
cookbook 'nginx', '~> 12.0'
cookbook 'firewall', '~> 3.0'
cookbook 'myapp', path: './cookbooks/myapp'
cookbook 'internal-tool', git: 'https://git.example.com/chef/internal-tool.git', branch: 'main'
```

```bash
berks install
berks upload
berks vendor cookbooks/
```

### Test-Kitchen (Integration Testing)

**`kitchen.yml`**:
```yaml
driver:
  name: vagrant
provisioner:
  name: chef_zero
  product_version: '18.3.0'
verifier:
  name: inspec
platforms:
  - name: ubuntu-22.04
  - name: centos-stream-9
suites:
  - name: default
    run_list: ["recipe[myapp::default]"]
    attributes: { myapp: { port: 8080 } }
```

```bash
kitchen list
kitchen converge ubuntu-2204
kitchen verify ubuntu-2204
kitchen test
```

### ChefSpec (Unit Testing)

```ruby
require 'spec_helper'
describe 'myapp::default' do
  platform 'ubuntu', '22.04'
  it 'installs nginx' do
    expect(chef_run).to install_package('nginx')
  end
  it 'creates nginx config' do
    expect(chef_run).to create_template('/etc/nginx/nginx.conf').with(owner: 'root', mode: '0644')
  end
  it 'enables and starts nginx' do
    expect(chef_run).to enable_service('nginx')
    expect(chef_run).to start_service('nginx')
  end
end
```

### Policyfiles (Replacing Roles + Environments)

```ruby
# Policyfile.rb
name 'myapp'
default_source :supermarket
run_list ['recipe[base]', 'recipe[myapp::default]']
cookbook 'myapp', path: './cookbooks/myapp'
default['myapp']['version'] = '1.0.0'
```

```bash
chef install Policyfile.rb          # Generate Policyfile.lock.json
chef push production Policyfile.rb  # Push to server
knife node policy set web01 myapp production
```





[← Previous](10-10-chef-dsl.md) | [↑ Index](index.md) | [Next →](12-12-comparative-analysis.md)
