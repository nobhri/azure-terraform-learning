# Retrospective: Start Through Phase 4

This document summarizes what has been learned from the beginning of the
repository through Phase 4.

The main conclusion is that the learning path is progressing well. The work has
not only added Terraform files; it has also exposed the practical boundaries
between Azure resources, Terraform state, local operator workflow, GitHub
Actions, OIDC authentication, and Azure RBAC.

## What Went Well

Phase 1 established the real Azure shape behind a small Linux VM. The VM is not
a standalone object. It depends on a NIC, the NIC depends on a subnet, and the
subnet depends on a virtual network. Public IP and NSG resources were then added
for explicit SSH access.

Phase 1 also surfaced a useful provider-side failure: an IPv6 address from
`curl ifconfig.me` was passed as an IPv4 SSH CIDR. The fix was to request an
IPv4 address explicitly:

```bash
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"
```

Expected result: Azure accepts the SSH source prefix for the NSG rule.

Reason: the learning VM uses an IPv4 public IP path, so the source CIDR should
also be IPv4.

Phase 2 separated `dev`, `staging`, and `prod` with `.tfvars` files and
environment-specific state. This made the difference between input values and
backend selection visible:

- `.tfvars` changes the desired names, tags, and other Terraform inputs.
- backend configuration changes where Terraform stores the resource mapping.

Phase 3 moved state to Azure Blob Storage. The most useful lesson was the
difference between `terraform init -reconfigure` and
`terraform init -migrate-state`. Using `-reconfigure` first does not copy local
state into the remote backend, but the situation can be recovered when the
correct local state file still exists:

```bash
terraform state push environments/dev/terraform.tfstate
```

Expected result: Terraform writes the local dev state snapshot to the currently
configured remote backend.

Reason: after backend reconfiguration, Terraform no longer has the old backend
migration context. An explicit state push is the direct recovery path.

Phase 4 introduced GitHub Actions as a validation runner and exposed a very
practical Azure boundary: authentication is not authorization. GitHub OIDC login
can succeed while Terraform backend access still fails because the service
principal lacks the right Azure RBAC role.

The final backend direction uses Microsoft Entra ID and OIDC instead of Storage
Account key lookup:

```bash
terraform init \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_oidc=true"
```

Expected result: CI initializes the Azure Blob Storage backend without
retrieving Storage Account keys.

Reason: `use_azuread_auth=true` and `use_oidc=true` keep backend access aligned
with short-lived GitHub OIDC credentials and Azure RBAC.

## Strong Learning Signals

The most important sign of progress is that mistakes were captured as learning
material instead of being hidden.

Examples:

- IPv6 public IP lookup caused an Azure NSG rule failure.
- A backend and var-file mismatch created the wrong dev resources.
- `terraform init -reconfigure` was used when state migration was intended.
- GitHub Actions OIDC login succeeded but backend RBAC was incomplete.
- Local backend init failed because the signed-in Azure CLI user and the GitHub
  Actions service principal are different actors.

These are useful failures because they reveal real operational boundaries. They
are also small enough to understand and document before the repository grows
more complex.

## Risks To Manage Next

The main risk after Phase 4 is command complexity.

Manual commands now combine:

- the selected environment backend file
- the selected environment `.tfvars` file
- the backend Storage Account name
- local or CI backend authentication options
- local `TF_VAR_*` values
- Azure RBAC for the actor running the command

This is the right time to improve command visibility and mistake prevention,
but not necessarily the right time to hide everything behind a task runner. The
learning value still comes from seeing each Terraform and Azure option.

Another risk is the current root module shape. The repository root is the only
Terraform root module, while `environments/dev`, `environments/staging`, and
`environments/prod` hold backend and input files. That is fine for learning
Phases 2 through 4, but it makes it possible to pair the wrong backend and
var-file.

Phase 5 should reduce that risk by introducing environment wrappers that call
modules from each environment directory.

## Recommended Direction

Keep full commands visible in documentation until the repeated patterns are
well understood.

Use docs before task runners:

- document the canonical command combinations
- explain the expected result
- explain why each option is present
- keep `apply` and `destroy` explicit

Then use Phase 5 to reshape the code so the normal working directory becomes
the environment itself:

```bash
cd environments/dev
terraform init
terraform plan
```

Expected result: the selected directory implies the environment.

Reason: environment wrappers reduce backend and var-file pairing mistakes
without hiding Terraform behavior behind a custom command layer.

## Current Assessment

The repository is in a good place for the next step. It has moved from a simple
VM example into the practical concerns that infrastructure engineers and data
platform engineers need to discuss: state, environment boundaries, CI
authentication, RBAC, and repeatable workflows.

The next improvement should not be a broad refactor. It should be a focused
Phase 5 module refactor that preserves the current Azure resources while making
environment boundaries harder to mix up.
