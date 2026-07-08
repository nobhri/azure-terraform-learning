# Phase 2: Multiple Environments

This phase keeps the Phase 1 Azure VM resources and separates them into
`dev`, `staging`, and `prod` environments.

The Terraform resource definitions still live at the repository root. Each
environment gets its own variable file and local state path so one environment
does not accidentally share state or resource names with another.

## What This Adds

- `environments/dev`
- `environments/staging`
- `environments/prod`
- Environment-specific local backend configuration
- Environment-specific `.tfvars` usage
- Environment-specific resource names and tags

## Why

Terraform state is the record of which real Azure resources belong to a
configuration. If multiple environments share one local state file, a plan for
`dev` can accidentally compare itself against `prod` resources.

Phase 2 avoids that by giving each environment:

- a separate backend path, such as `environments/dev/terraform.tfstate`
- a separate variable file, such as `environments/dev/dev.tfvars`
- a separate `project_name`, such as `terraform-learning-dev`

## Backend And Tfvars

The backend file and the `.tfvars` file solve different problems.

The `.tfvars` file controls values used by the Terraform configuration:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform uses dev-specific variable values, such as
`project_name = "terraform-learning-dev"` and `environment = "dev"` tags.

The backend file controls where Terraform stores state:

```bash
terraform init -reconfigure -backend-config=environments/dev/backend.hcl
```

Expected result: Terraform reads and writes state at
`environments/dev/terraform.tfstate`.

Reason: Terraform must know where state lives before it evaluates normal input
variables. Backend configuration cannot use values such as `var.project_name`,
so the state path is selected during `terraform init`, not during
`terraform plan` or `terraform apply`.

The same backend value can be passed inline:

```bash
terraform init -reconfigure -backend-config="path=environments/dev/terraform.tfstate"
```

Expected result: Terraform uses the same dev local state path.

This repository uses `backend.hcl` files instead because they make the
environment-to-state mapping visible, reduce command length, and prepare for
Phase 3, where the backend configuration will move to Azure Blob Storage.

## Command Roles

These commands do different checks, and only some of them need the backend to
be initialized first.

`terraform fmt` formats Terraform files. It does not read state, call Azure, or
need the Azure provider. It can run before `terraform init`.

`terraform init` prepares the working directory. It initializes the backend,
downloads or checks providers, reads `.terraform.lock.hcl`, and prepares modules
if the configuration uses them. In this phase, the most visible job is selecting
the local state path for the active environment.

`terraform validate` checks whether the Terraform configuration is valid. It
uses provider schemas, so it normally runs after `terraform init`. It does not
compare the configuration with Azure resources or show what will change.

`terraform plan` compares the configuration, the selected state, and real Azure
resources. This is the command that shows what Terraform intends to create,
update, or destroy.

`terraform apply` makes the planned changes. `terraform destroy` removes
resources managed by the selected state.

For environment work, the important pairing is:

```bash
terraform init -reconfigure -backend-config=environments/dev/backend.hcl
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: both the state path and variable values point to `dev`.

Reason: `init` selects the state boundary, while `-var-file` selects the input
values. If these point to different environments, the plan becomes confusing and
can be risky.

## Current Limits

The Phase 2 workflow is intentionally manual. That makes the state and variable
boundaries visible, but it is not the shape to use for a mature team workflow.

The main risks are:

- forgetting `-var-file`
- selecting one environment with `terraform init` and another with `-var-file`
- not noticing which local backend is currently active
- relying on local state instead of shared state with locking

Later phases add guardrails:

- Phase 3 moves state to Azure Blob Storage and introduces GitHub Actions.
- Phase 4 moves toward environment wrapper directories and reusable modules.
- Phase 6 adds stronger CI/CD checks, plans, approvals, and environment
  protection.

This phase keeps those safeguards out on purpose so the underlying Terraform
mechanics are clear before abstraction and automation are added.

## Prerequisites

- Complete the Phase 1 prerequisites
- Terraform initialized at least once in this repository
- Azure CLI logged in to the subscription used for this learning project
- SSH public key available locally

Log in to Azure:

```bash
az login
az account set --subscription "<subscription-id>"
```

Expected result: Azure CLI is authenticated and set to the subscription used for
this learning project.

Set values that should stay local:

```bash
export TF_VAR_subscription_id="$(az account show --query id -o tsv)"
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"
```

Expected result: Terraform can read the subscription ID, SSH public key, and
trusted SSH source CIDR without committing them to the repository.

## Create A Local Environment Variable File

Copy the example file for the environment you want to use:

```bash
cp environments/dev/dev.tfvars.example environments/dev/dev.tfvars
```

Expected result: `environments/dev/dev.tfvars` exists locally and is ignored by
Git.

Review the local file:

```bash
terraform fmt environments/dev/dev.tfvars
```

Expected result: Terraform formats the variable file if needed.

Reason: `.tfvars.example` files are committed as templates. Real `.tfvars`
files are local because they may later contain environment-specific or sensitive
values.

## Use The Dev Environment

Configure Terraform to use the dev local state path:

```bash
terraform init -reconfigure -backend-config=environments/dev/backend.hcl
```

Expected result: Terraform uses `environments/dev/terraform.tfstate` as the
local state file.

Format and validate:

```bash
terraform fmt
terraform validate
```

Expected result: formatting completes and validation reports that the
configuration is valid.

Review the dev plan:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform plans resources named with the
`terraform-learning-dev` prefix and tagged with `environment = "dev"`.

Create the dev resources only when you are ready:

```bash
terraform apply -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform creates the dev Resource Group, network resources,
NSG, Public IP, NIC, and Linux VM.

Destroy dev resources when finished:

```bash
terraform destroy -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform removes the dev learning resources to avoid ongoing
Azure cost.

## Switch Environments

Before planning another environment, reconfigure the backend:

```bash
cp environments/staging/staging.tfvars.example environments/staging/staging.tfvars
terraform init -reconfigure -backend-config=environments/staging/backend.hcl
terraform plan -var-file=environments/staging/staging.tfvars
```

Expected result: Terraform reads and writes staging state at
`environments/staging/terraform.tfstate` and plans resources with the staging
prefix and tags.

For production:

```bash
cp environments/prod/prod.tfvars.example environments/prod/prod.tfvars
terraform init -reconfigure -backend-config=environments/prod/backend.hcl
terraform plan -var-file=environments/prod/prod.tfvars
```

Expected result: Terraform reads and writes production state at
`environments/prod/terraform.tfstate` and plans resources with the production
prefix and tags.

Reason: with a local backend, the selected backend path is part of the working
directory setup. Re-running `terraform init -reconfigure` makes the active
environment explicit before each plan or apply.

## Safety Check

Before committing, confirm local state and real `.tfvars` files are ignored:

```bash
git status --short
```

Expected result: example files, docs, and backend config files may appear, but
`terraform.tfstate`, `terraform.tfstate.backup`, and real `.tfvars` files do not.

Do not run `terraform apply` for staging or prod just because the examples
exist. In this learning repository, create only the environment you currently
need, then destroy it when the lesson is complete.

## Troubleshooting

If you initialized the dev backend but accidentally ran this command without a
variable file:

```bash
terraform apply
```

Terraform used the active dev state path, but it used the defaults from
`variables.tf` instead of `environments/dev/dev.tfvars`.

That usually means:

- state path: `environments/dev/terraform.tfstate`
- resource names: `terraform-learning-*`
- tags: `environment = "learning"` and `phase = "1"`

To clean this up, keep the same backend selected and review a destroy plan
without a variable file:

```bash
terraform init -reconfigure -backend-config=environments/dev/backend.hcl
terraform plan -destroy
```

Expected result: Terraform shows only the accidentally created default-named
resources.

If the destroy plan matches the resources you created by mistake, destroy them:

```bash
terraform destroy
```

Expected result: Terraform removes the resources recorded in the active dev
state.

Reason: use the same backend and the same variable inputs used for the mistaken
apply. Adding `-var-file=environments/dev/dev.tfvars` during cleanup would use
different input values from the apply that created the resources.
