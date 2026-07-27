## ✅ Self-Test — Part 51: Infrastructure as Code — Terraform

**Score:** 12/15 correct = ready for Part 52.

1. What is the difference between declarative and imperative infrastructure provisioning?

2. What does `terraform init` do?

3. What is the purpose of the state file?

4. How does Terraform detect drift?

5. What is the difference between `count` and `for_each`?

6. What is the variable precedence order in Terraform (highest to lowest)?

7. Why is remote state important for teams?

8. What is a Terraform module, and why use one?

9. How do workspaces help manage multiple environments?

10. What is the `required_version` setting in the `terraform` block?

11. When should you use a provisioner, and when should you avoid it?

12. What is the purpose of state locking, and how is it implemented with S3 + DynamoDB?

13. What tool would you use to scan Terraform code for security vulnerabilities?

14. What is the difference between `terraform plan` and `terraform apply`?

15. Explain how Terraform builds and traverses its dependency graph.

**Answers:**

1. **Declarative**: specify desired end state (Terraform). **Imperative**: specify step-by-step instructions (Bash). Declarative is idempotent and handles drift automatically.

2. `terraform init` downloads required providers and modules, initializes the backend (local or remote), and sets up the working directory.

3. The state file maps your configuration to real infrastructure resources. It tracks resource IDs, attributes, dependencies, and metadata. It's how Terraform knows what exists and what needs to change.

4. Terraform calls the provider's `ReadResource` RPC during `refresh` (before plan/apply), which queries the real API. It compares the returned attributes with those in the state file. Differences = drift.

5. **`count`**: Creates a numbered list of resources. Resources are accessed by index (`resource[0]`, `resource[1]`). **`for_each`**: Creates a map keyed by a unique identifier. Resources are accessed by key (`resource["key"]`). Use `for_each` when you need stable, meaningful keys.

6. Highest to lowest: (1) `-var` / `-var-file` CLI flags, (2) `*.auto.tfvars` files, (3) `terraform.tfvars` file, (4) `TF_VAR_*` environment variables, (5) `default` in the variable block.

7. Remote state enables collaboration (team shares the same state), provides backup (state survives machine failure), enables locking (prevents concurrent corruption), and integrates with CI/CD pipelines.

8. A **module** is a reusable group of Terraform resources. Modules enforce encapsulation and abstraction, allow version pinning, and can be shared via the Terraform Registry or private registries.

9. Workspaces create separate state files for the same configuration. You can use `terraform.workspace` to vary configuration per environment, run `terraform workspace select dev` to target dev, etc.

10. `required_version` enforces a minimum (or range of) Terraform CLI version(s). If the installed version doesn't match, Terraform exits with an error. Example: `required_version = ">= 1.5.0"`.

11. Use provisioners **only as a last resort** when no other mechanism works. Avoid them because they're not idempotent, not re-runnable on updates, and slow. Prefer **cloud-init/userdata**, **Packer AMIs**, or **configuration management tools** (Ansible, Chef, etc.).

12. State locking prevents two concurrent `terraform apply` operations from corrupting the state file. With S3 + DynamoDB, Terraform creates a DynamoDB item with a `LockID` key. The lock is acquired before an operation and released after. If another operation tries to lock, it gets an error.

13. **checkov**, **tflint**, **terrascan**, **tfsec** — all scan Terraform configurations for security misconfigurations (open security groups, unencrypted storage, hardcoded secrets, etc.).

14. `terraform plan` is a **dry run** — it shows what will change without making changes. `terraform apply` **executes** the changes (creates, updates, destroys resources). Always review a plan before applying.

15. Terraform parses all `.tf` files into an **AST**, then builds a **directed acyclic graph (DAG)** by analyzing resource references (attribute references and `depends_on`). It traverses the graph in **topological order**: resources with no dependencies first, then dependent resources. Providers process resource operations in parallel where no dependencies exist. The graph supports two strategies: **create-before-destroy** (marked with lifecycle) and default **destroy-before-create**.

**Scoring:**
- 13-15 correct: Excellent — you're ready for Kubernetes!
- 10-12 correct: Good — review sections 4, 7, and 11 before moving on
- 0-9 correct: Review this entire part and try again

---



---

[← Previous](19-whats-coming-in-part-52.md) | [↑ Index](index.md) | [Next →](21-references.md)
