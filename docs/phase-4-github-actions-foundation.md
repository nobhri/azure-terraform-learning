# Phase 4: GitHub Actions Foundation

This phase adds GitHub Actions as a low-risk Terraform validation runner.

The workflow authenticates to Azure with OIDC, initializes the existing Azure
Blob Storage remote backend, and runs basic validation checks. It does not run
`terraform plan`, `terraform apply`, or `terraform destroy`.

## What This Adds

- GitHub Actions workflow
- OIDC authentication from GitHub to Azure
- Repository secrets for Azure login and backend selection in this public
  learning repository
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

## Repository Secrets For This Public Repo

Configure these GitHub repository secrets:

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

These values are identifiers and configuration values, not long-lived
credentials. They identify the Azure application, tenant, subscription, and
backend Storage Account, but they are not enough to authenticate by themselves.
Authentication happens through GitHub OIDC and the Azure federated credential.

In a private work repository with controlled collaborator access, repository
variables would usually be enough for these values. This learning repository is
public, and the workflow may change during experiments. Store them as
repository secrets here so accidental log output is more likely to be masked by
GitHub Actions.

The Storage Account name is also not a credential, but it is
subscription-specific configuration. Keep it in a repository secret for this
public repo instead of committing it to the backend files.

Set the secrets with GitHub CLI after the values are available in your shell:

```bash
gh secret set AZURE_CLIENT_ID --body "$AZURE_CLIENT_ID"
gh secret set AZURE_TENANT_ID --body "$AZURE_TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID"
gh secret set TFSTATE_STORAGE_ACCOUNT --body "$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: the repository has the secrets needed by the workflow.

Reason: repository secrets are available to GitHub Actions through the
`secrets` context and are masked in logs when GitHub recognizes the exact value.

When you run `gh secret set` from inside this repository, `gh` uses the current
repository automatically. You can still add `--repo "$GITHUB_REPOSITORY"`
when you want the command to be explicit or when you run it from another
directory:

```bash
export GITHUB_REPOSITORY="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"

gh secret set AZURE_CLIENT_ID --body "$AZURE_CLIENT_ID" --repo "$GITHUB_REPOSITORY"
gh secret set AZURE_TENANT_ID --body "$AZURE_TENANT_ID" --repo "$GITHUB_REPOSITORY"
gh secret set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID" --repo "$GITHUB_REPOSITORY"
gh secret set TFSTATE_STORAGE_ACCOUNT --body "$TFSTATE_STORAGE_ACCOUNT" --repo "$GITHUB_REPOSITORY"
```

Expected result: the same secrets are set on the repository returned by
`gh repo view`.

Reason: making the repository explicit prevents accidentally setting secrets on
a different repository if the command is copied into another directory.

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

Reason: Terraform can use the same shell value for local `terraform init`
commands and for the GitHub repository secret.

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

Create an Azure application and service principal for this GitHub Actions
workflow:

```bash
export AZURE_APP_NAME="terraform-learning-github-actions"
export AZURE_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export AZURE_TENANT_ID="$(az account show --query tenantId --output tsv)"

export AZURE_CLIENT_ID="$(az ad app create \
  --display-name "$AZURE_APP_NAME" \
  --query appId \
  --output tsv)"

az ad sp create --id "$AZURE_CLIENT_ID"
```

Expected result: Azure creates an application registration and a service
principal. `AZURE_CLIENT_ID` contains the application client ID used by
`azure/login`.

Reason: GitHub Actions logs in as this Azure application. No client secret is
created because OIDC uses short-lived tokens.

If you already created the application, recover the IDs instead of creating a
second one:

```bash
export AZURE_APP_NAME="terraform-learning-github-actions"
export AZURE_CLIENT_ID="$(az ad app list \
  --display-name "$AZURE_APP_NAME" \
  --query "[0].appId" \
  --output tsv)"
export AZURE_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export AZURE_TENANT_ID="$(az account show --query tenantId --output tsv)"
```

Expected result: the current shell has the existing application client ID,
tenant ID, and subscription ID.

Reason: repeated practice sessions should reuse the same application when it
already exists.

Grant the service principal access to the Terraform backend Resource Group:

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

Expected result: the service principal can read and write Terraform state blobs
in the backend Resource Group.

Reason: `terraform init` needs access to the Azure Blob Storage backend before
`terraform validate` can run in GitHub Actions.

If the role assignment already exists, Azure may return a conflict message. That
is okay; it means the permission is already present.

Add a federated credential for the repository pull request workflow:

```bash
export GITHUB_REPOSITORY="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
export AZURE_APP_OBJECT_ID="$(az ad app show \
  --id "$AZURE_CLIENT_ID" \
  --query id \
  --output tsv)"

cat > /tmp/terraform-learning-github-pr-credential.json <<EOF
{
  "name": "github-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_REPOSITORY}:pull_request",
  "description": "GitHub Actions pull_request workflow for Terraform validation",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az ad app federated-credential create \
  --id "$AZURE_APP_OBJECT_ID" \
  --parameters /tmp/terraform-learning-github-pr-credential.json
```

Expected result: GitHub Actions can request an Azure token when the workflow
runs from this repository.

Reason: the workflow needs Azure access to initialize the remote backend and
load provider metadata without using a stored Azure client secret.

After the Azure application, service principal, role assignment, and federated
credential are ready, send the values directly to GitHub repository secrets:

```bash
gh secret set AZURE_CLIENT_ID --body "$AZURE_CLIENT_ID" --repo "$GITHUB_REPOSITORY"
gh secret set AZURE_TENANT_ID --body "$AZURE_TENANT_ID" --repo "$GITHUB_REPOSITORY"
gh secret set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID" --repo "$GITHUB_REPOSITORY"
gh secret set TFSTATE_STORAGE_ACCOUNT --body "$TFSTATE_STORAGE_ACCOUNT" --repo "$GITHUB_REPOSITORY"
```

Expected result: no manual copy and paste is needed. `gh` receives the values
from shell variables populated by `az` and the backend lookup command.

Reason: this keeps the setup repeatable while avoiding long-lived Azure client
secrets.

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
- If the workflow fails because a repository secret is missing, add or fix the
  secret and push a small follow-up commit.

Expected result: the pull request shows a passing Terraform workflow without
running `terraform plan`, `terraform apply`, or `terraform destroy`.

Reason: Phase 4 proves GitHub Actions can authenticate and validate the
Terraform root module, while infrastructure change review and deployment stay
out of scope.

Do not run `terraform apply` or `terraform destroy` for this phase unless that
is a separate explicit exercise.
