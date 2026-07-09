# Phase 4: GitHub Actions Foundation

This phase adds GitHub Actions as a low-risk Terraform validation runner.

The workflow authenticates to Azure with OIDC, initializes the existing Azure
Blob Storage remote backend, and runs basic validation checks. It does not run
`terraform plan`, `terraform apply`, or `terraform destroy`.

## What This Adds

- GitHub Actions workflow
- OIDC authentication from GitHub to Azure
- Repository variables for Azure login and backend selection
- `terraform fmt -check`
- `terraform init`
- `terraform validate`

## Why

Phase 3 moved Terraform state into Azure Blob Storage. A GitHub Actions runner
starts from a clean machine, so it needs explicit authentication and backend
configuration before Terraform can validate the root module.

OIDC lets GitHub request a short-lived Azure token for this repository workflow.
That avoids storing a long-lived Azure client secret in GitHub.

This phase keeps the workflow intentionally small. Formatting, initialization,
and validation are useful checks, but they do not propose or apply
infrastructure changes. `terraform plan` is deferred to Phase 9, and controlled
apply is deferred to Phase 10.

## Repository Variables

Configure these GitHub repository variables:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
TFSTATE_STORAGE_ACCOUNT
```

Expected result: the workflow can identify the Azure application, tenant,
subscription, and remote backend Storage Account.

Reason: the Azure login action needs the application, tenant, and subscription
values for OIDC authentication. Terraform also needs the Storage Account name
because Phase 3 intentionally did not commit the random backend Storage Account
name.

The Storage Account name is not a secret, but it is subscription-specific
configuration. Keep it in a repository variable instead of committing it to the
backend files.

Set the variables with GitHub CLI if the values are already available in your
shell:

```bash
gh variable set AZURE_CLIENT_ID --body "$AZURE_CLIENT_ID"
gh variable set AZURE_TENANT_ID --body "$AZURE_TENANT_ID"
gh variable set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID"
gh variable set TFSTATE_STORAGE_ACCOUNT --body "$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: the repository has the variables needed by the workflow.

Reason: repository variables are available to GitHub Actions without treating
these non-secret identifiers as long-lived credentials.

## Find The Backend Storage Account

If `TFSTATE_STORAGE_ACCOUNT` is no longer available in your shell, list the
Storage Accounts in the backend Resource Group:

```bash
az storage account list \
  --resource-group terraform-learning-tfstate-rg \
  --query "[].name" \
  --output table
```

Expected result: Azure prints the backend Storage Account name, usually with a
`tflearn` prefix.

Reason: Phase 3 used a random suffix so the Storage Account name would be
globally unique, while the backend Resource Group name stayed fixed.

If there is only one Storage Account in that Resource Group, set the shell
variable again:

```bash
export TFSTATE_STORAGE_ACCOUNT="$(az storage account list \
  --resource-group terraform-learning-tfstate-rg \
  --query "[0].name" \
  --output tsv)"
```

Expected result: the shell variable contains the backend Storage Account name.

Reason: Terraform can use the same variable value for local `terraform init`
commands and for the GitHub repository variable.

If more than one Storage Account exists, include creation time:

```bash
az storage account list \
  --resource-group terraform-learning-tfstate-rg \
  --query "[].{name:name, created:creationTime, location:primaryLocation}" \
  --output table
```

Expected result: Azure prints enough context to choose the backend Storage
Account created for this learning repository.

Reason: random suffixes make names unique but harder to remember after the
original shell session ends.

## Azure OIDC Setup

Create or identify an Azure application / service principal for this GitHub
Actions workflow.

Add a federated credential for the repository pull request workflow.

Expected result: GitHub Actions can request an Azure token when the workflow
runs from this repository.

Reason: the workflow needs Azure access to initialize the remote backend and
load provider metadata without using a stored Azure client secret.

The workflow requires this permission:

```yaml
permissions:
  contents: read
  id-token: write
```

Expected result: GitHub can checkout the repository and request an OIDC token.

Reason: `id-token: write` allows the Azure login action to request the
short-lived identity token that Azure validates against the federated
credential.

## Workflow Commands

The workflow runs:

```bash
terraform fmt -check
```

Expected result: Terraform files are already formatted.

Reason: formatting is a fast check that does not require Azure access.

Then it initializes the dev backend:

```bash
terraform init \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: Terraform configures the Azure Blob Storage backend with the
`dev/terraform.tfstate` key.

Reason: Phase 4 validates one environment first. Later phases can add an
environment matrix and plan output.

Finally it validates:

```bash
terraform validate
```

Expected result: Terraform reports that the configuration is valid.

Reason: validation checks Terraform syntax and provider schemas after the
working directory has been initialized.

## Local Verification

Before opening a pull request, run:

```bash
terraform fmt -check
```

Expected result: no files need formatting.

Reason: this mirrors the first Terraform check in CI and does not require Azure
access.

If Azure CLI is authenticated and `TFSTATE_STORAGE_ACCOUNT` is set, run:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
terraform validate
```

Expected result: Terraform initializes the dev remote backend and validates the
configuration.

Reason: these commands match the workflow behavior before GitHub Actions runs
them on a pull request.

## Pull Request Verification Todo

After this branch is pushed and a draft pull request is opened, verify these
items in GitHub:

- Confirm the Terraform workflow starts on the pull request.
- Confirm the Azure login step succeeds with OIDC.
- Confirm `terraform init` uses the `dev/terraform.tfstate` backend key.
- Confirm `terraform fmt -check` and `terraform validate` complete
  successfully.
- If the workflow fails because a repository variable is missing, add or fix
  the variable and push a small follow-up commit.

Expected result: the pull request shows a passing Terraform workflow without
running `terraform plan`, `terraform apply`, or `terraform destroy`.

Reason: Phase 4 proves GitHub Actions can authenticate and validate the
Terraform root module, while infrastructure change review and deployment stay
out of scope.

Do not run `terraform apply` or `terraform destroy` for this phase unless that
is a separate explicit exercise.
