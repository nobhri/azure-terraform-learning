# Phase 5: Terraform Modules

Phase 5 keeps the existing Azure architecture and reorganizes it into reusable
modules. Each environment directory is now an independent Terraform root
module, so the working directory identifies the environment being changed.

## Structure

```text
modules/
  network/
  linux-vm/
environments/
  dev/
  staging/
  prod/
```

The network module owns the Resource Group, VNet, subnet, NSG, Public IP, and
NIC. The Linux VM module receives the Resource Group name and NIC ID through
module inputs. This makes the dependency between networking and compute visible
in each environment wrapper.

## Prepare Dev

Create a local variable file from the committed example:

```bash
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

Expected result: dev has a local `terraform.tfvars` file that Terraform loads
automatically when commands run from `environments/dev`.

Reason: local `.tfvars` files may contain machine- or subscription-specific
values and are intentionally ignored by Git.

Set the inputs that should not be committed:

```bash
export TF_VAR_subscription_id="$(az account show --query id -o tsv)"
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"
```

Expected result: Terraform receives the Azure subscription, public SSH key,
and trusted source address without storing them in the repository.

## Initialize And Validate

Run Terraform from the dev wrapper:

```bash
cd environments/dev

terraform init -reconfigure \
  -backend-config=backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true"

terraform validate
terraform plan
```

Expected result: initialization uses the existing dev backend key, validation
succeeds, and the plan displays address moves into `module.network` and
`module.linux_vm` without replacing unchanged Azure resources.

Reason: the `moved` blocks declare how the old root resource addresses map to
their new module addresses. This records the refactor in code and avoids a
series of manual `terraform state mv` commands.

Read the entire plan before applying. A module refactor should not propose
unexpected resource replacement. Do not apply until the plan contains only the
expected address moves and any intentional tag changes.

## Other Environments

Repeat the same commands from `environments/staging` or `environments/prod`
only when validating that environment. Each directory has its own backend key
and variable example.

Expected result: Terraform cannot accidentally combine a dev variable file
with the prod backend simply because both paths were passed from the repository
root.

Reason: the environment directory is now the root module and contains both its
backend configuration and module calls.

Destroy learning resources after the exercise unless they are intentionally
needed for the next phase.
