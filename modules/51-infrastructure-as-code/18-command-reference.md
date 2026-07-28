## 📊 Command Reference

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize working directory, download providers/modules |
| `terraform init -upgrade` | Upgrade providers to latest within constraints |
| `terraform init -migrate` | Migrate state to a new backend |
| `terraform init -reconfigure` | Reconfigure backend (discard previous config) |
| `terraform plan` | Show execution plan (dry run) |
| `terraform plan -out=tfplan` | Save plan to file |
| `terraform plan -target=resource` | Plan only a specific resource |
| `terraform apply` | Apply changes |
| `terraform apply -auto-approve` | Apply without confirmation |
| `terraform apply tfplan` | Apply a saved plan |
| `terraform destroy` | Destroy all managed resources |
| `terraform destroy -target=resource` | Destroy a specific resource |
| `terraform validate` | Validate configuration syntax |
| `terraform fmt` | Format configuration files |
| `terraform fmt -check -recursive` | Check formatting (useful in CI) |
| `terraform state list` | List resources in state |
| `terraform state show RESOURCE` | Show resource details |
| `terraform state mv OLD NEW` | Rename/move resource in state |
| `terraform state rm RESOURCE` | Remove resource from state (no destroy) |
| `terraform state pull` | Pull remote state to stdout |
| `terraform state push` | Push state file (dangerous) |
| `terraform import ADDRESS ID` | Import existing resource |
| `terraform output` | Show output values |
| `terraform output -json` | Outputs in JSON format |
| `terraform workspace list` | List workspaces |
| `terraform workspace new NAME` | Create new workspace |
| `terraform workspace select NAME` | Switch workspace |
| `terraform workspace show` | Show current workspace |
| `terraform force-unlock ID` | Force release of state lock |
| `terraform graph` | Generate DOT graph of dependencies |
| `terraform providers` | Show provider requirements |
| `terraform version` | Show Terraform version |
| `terraform -install-autocomplete` | Install shell autocomplete |

### Companion Tools

| Tool | Purpose | Install |
|------|---------|---------|
| **tflint** | Terraform linter | `brew install tflint` / script install |
| **checkov** | Security scanner | `pip install checkov` |
| **terrascan** | Static analysis | `brew install terrascan` / binary install |
| **tfsec** | Security scanner | `brew install tfsec` |
| **infracost** | Cost estimation | `brew install infracost` |
| **terratest** | Go test framework | `go get github.com/gruntwork-io/terratest` |
| **terraform-docs** | Doc generator | `brew install terraform-docs` |
| **hcledit** | HCL manipulation | `brew install hcledit` |





[← Previous](17-section-16-hands-on-practices.md) | [↑ Index](index.md) | [Next →](19-whats-coming-in-part-52.md)
