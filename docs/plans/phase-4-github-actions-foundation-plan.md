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
    env:
      TFSTATE_STORAGE_ACCOUNT: ${{ secrets.TFSTATE_STORAGE_ACCOUNT }}
    steps:
      - uses: actions/checkout@v4

      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - uses: hashicorp/setup-terraform@v3

      - run: terraform fmt -check

      - run: |
          terraform init \
            -backend-config=environments/dev/backend.hcl \
            -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"

      - run: terraform validate
```

This workflow intentionally validates only one environment at first. A later
phase can add environment matrices, plan output, and apply controls.

## GitHub Secrets

Document these repository secrets:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
TFSTATE_STORAGE_ACCOUNT
```

Expected result: GitHub Actions can identify the Azure application, tenant,
subscription, and backend Storage Account used for OIDC login and Terraform
backend initialization.

Reason: OIDC uses a federated token from GitHub instead of a stored Azure client
secret. In a private work repository these values would normally fit repository
variables, but this learning repository is public, so storing them as repository
secrets reduces accidental log exposure during experiments.

Include commands that populate the values from Azure CLI and pass them directly
to GitHub CLI:

```bash
export AZURE_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export AZURE_TENANT_ID="$(az account show --query tenantId --output tsv)"
export GITHUB_REPOSITORY="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"

gh secret set AZURE_CLIENT_ID --body "$AZURE_CLIENT_ID" --repo "$GITHUB_REPOSITORY"
gh secret set AZURE_TENANT_ID --body "$AZURE_TENANT_ID" --repo "$GITHUB_REPOSITORY"
gh secret set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID" --repo "$GITHUB_REPOSITORY"
gh secret set TFSTATE_STORAGE_ACCOUNT --body "$TFSTATE_STORAGE_ACCOUNT" --repo "$GITHUB_REPOSITORY"
```

Expected result: setup can be repeated without manually copying values into
`gh secret set`.

Reason: `gh` uses the current repository automatically, but `--repo` makes the
target explicit and safer when commands are copied elsewhere.

## Azure OIDC Setup To Document

Create or identify an Azure application / service principal for GitHub Actions:

```bash
export AZURE_APP_NAME="terraform-learning-github-actions"
export AZURE_CLIENT_ID="$(az ad app create \
  --display-name "$AZURE_APP_NAME" \
  --query appId \
  --output tsv)"

az ad sp create --id "$AZURE_CLIENT_ID"
```

Grant backend access:

```bash
export AZURE_SP_OBJECT_ID="$(az ad sp show \
  --id "$AZURE_CLIENT_ID" \
  --query id \
  --output tsv)"
export TFSTATE_RESOURCE_GROUP_ID="$(az group show \
  --name terraform-learning-tfstate-rg \
  --query id \
  --output tsv)"

az role assignment create \
  --assignee-object-id "$AZURE_SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID"
```

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
- Why `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` are
  identifiers, but are stored as repository secrets in this public learning repo
- Why no Azure client secret is used
- How to find the backend Storage Account name if the shell variable is gone
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

After GitHub secrets and Azure federated credentials are configured, open a
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
