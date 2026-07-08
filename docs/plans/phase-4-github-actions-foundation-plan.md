# Phase 4 Plan: GitHub Actions Foundation

## Goal

Introduce GitHub Actions as a low-risk Terraform validation runner after the
Azure Blob Storage remote backend exists.

This phase should add OIDC authentication and basic checks only. It should not
add `terraform plan`, `terraform apply`, or deployment approvals.

## Planned Changes

- Add `.github/workflows/terraform.yml`.
- Configure GitHub Actions permissions for OIDC.
- Use Azure login with federated credentials.
- Install Terraform in the workflow.
- Run:
  - `terraform fmt -check`
  - `terraform init -backend-config=environments/dev/backend.hcl`
  - `terraform validate`
- Add a Phase 4 guide under `docs/`.
- Update `README.md` so Phase 4 becomes the next current focus after Phase 3 is
  complete.

## Workflow Shape

The first workflow should run on pull requests and keep the command set small:

```yaml
name: Terraform

on:
  pull_request:

permissions:
  contents: read
  id-token: write

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - uses: hashicorp/setup-terraform@v3

      - run: terraform fmt -check

      - run: terraform init -backend-config=environments/dev/backend.hcl

      - run: terraform validate
```

This workflow intentionally validates only one environment at first. A later
phase can add environment matrices, plan output, and apply controls.

## GitHub Variables

Document these repository variables:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

Expected result: GitHub Actions can identify the Azure application, tenant, and
subscription used for OIDC login.

Reason: OIDC uses a federated token from GitHub instead of a stored Azure client
secret.

## Azure OIDC Setup To Document

Create or identify an Azure application / service principal for GitHub Actions.

Add a federated credential for the repository and pull request workflow.

Expected result: GitHub Actions can request an Azure token when the workflow
runs from the configured repository context.

Reason: the workflow needs Azure access to initialize the remote backend and
load provider metadata without storing a long-lived secret.

## Documentation To Add

Create `docs/phase-4-github-actions-foundation.md` with:

- What GitHub Actions adds after remote backend
- Why the runner needs explicit Azure authentication
- What OIDC is at a practical level
- Why `id-token: write` is needed
- Why `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` can be
  repository variables
- Why no Azure client secret is used
- Why this phase runs `fmt`, `init`, and `validate` only
- Why `terraform plan` is deferred to Phase 9
- Why `terraform apply` is deferred to Phase 10

## Verification

Check formatting locally:

```bash
terraform fmt -check
```

Expected result: Terraform files are already formatted.

Reason: this mirrors the first Terraform check in CI and does not require Azure
access.

After GitHub variables and Azure federated credentials are configured, open a
pull request.

Expected result: the Terraform workflow runs and completes `fmt`, `init`, and
`validate`.

Reason: the workflow verifies that GitHub Actions can authenticate to Azure and
initialize the remote backend.

Do not add or run `terraform apply` in this phase.

## Out Of Scope

- `terraform plan` in CI
- Plan artifacts
- PR plan comments
- `terraform apply`
- `terraform destroy`
- GitHub Environments
- Approval gates
- Environment matrix
