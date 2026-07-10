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

Expected result: the service principal has this role on the backend Resource
Group:

```text
Storage Blob Data Contributor
```

Reason: the workflow initializes the backend with Microsoft Entra ID and OIDC,
so Terraform accesses the state blob through Azure RBAC instead of retrieving a
Storage Account key. `Storage Blob Data Contributor` allows Terraform to read
and update the state blob inside the backend container.

Do not grant `Storage Account Key Operator Service Role` for this phase. That
role would allow `Microsoft.Storage/storageAccounts/listKeys/action`, causing
Terraform to retrieve a Storage Account key and use shared-key authentication
for the backend. This workflow intentionally avoids that path so the GitHub
Actions backend access stays aligned with OIDC and RBAC.

`Reader` on the backend Storage Account is only required if the backend needs to
look up the blob endpoint from the Azure management plane, such as when
`lookup_blob_endpoint=true` is used. This repository does not set that option,
so the backend can infer the blob endpoint from the Storage Account name and
container name.

If the role assignment already exists, Azure may return a conflict message. That
is okay; it means the permission is already present.

Confirm the assigned roles:

```bash
az role assignment list \
  --assignee "$AZURE_SP_OBJECT_ID" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID" \
  --query "[].{role:roleDefinitionName, scope:scope}" \
  --output table
```

Expected result: Azure prints the required backend data-plane role at the
backend Resource Group scope.

```text
Role                           Scope
-----------------------------  ------------------------------------------------
Storage Blob Data Contributor  /subscriptions/.../resourceGroups/terraform-learning-tfstate-rg
```

Reason: a successful OIDC login only proves GitHub can authenticate as the
service principal. Terraform still needs Azure RBAC authorization to read the
backend Storage Account and access the state blob.

If a role was assigned at the Storage Account scope instead of the Resource
Group scope, use a broader query to find it:

```bash
az role assignment list \
  --assignee "$AZURE_SP_OBJECT_ID" \
  --query "[?contains(scope, 'terraform-learning-tfstate-rg')].{role:roleDefinitionName, scope:scope}" \
  --output table
```

Expected result: Azure prints matching role assignments whose scope contains
the backend Resource Group name.

Reason: exact `--scope` filtering only returns assignments at that exact scope.
It does not show child-scope assignments such as a role assigned directly to the
Storage Account.

## Local Backend Access

The GitHub Actions service principal and your local Azure CLI user are separate
Azure identities. Giving the service principal access does not give your local
user access to the backend state blob.

Check whether your local user has backend blob access:

```bash
export AZURE_USER_OBJECT_ID="$(az ad signed-in-user show \
  --query id \
  --output tsv)"

az role assignment list \
  --assignee "$AZURE_USER_OBJECT_ID" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID" \
  --query "[].{role:roleDefinitionName, scope:scope}" \
  --output table
```

Expected result: Azure prints `Storage Blob Data Contributor` for your user at
the backend Resource Group scope.

Reason: local `terraform init` with `use_cli=true` uses your Azure CLI identity
to list and read blobs in the Terraform state container.

If the role is missing, grant it to your local user:

```bash
az role assignment create \
  --assignee-object-id "$AZURE_USER_OBJECT_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID"
```

Expected result: your local Azure CLI user can access the backend state blob
through Azure RBAC.

Reason: without this data-plane role, local backend initialization may fail with
`AuthorizationPermissionMismatch` while listing blobs, even if `az login`
succeeds.

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
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_oidc=true"
```

Expected result: Terraform configures the Azure Blob Storage backend with the
`dev/terraform.tfstate` key and authenticates to the backend with GitHub OIDC
and Microsoft Entra ID.

Reason: Phase 4 validates one environment first. The backend authentication
flags are passed only in the CI command because GitHub Actions has an OIDC token
available. Later phases can add an environment matrix and plan output.

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
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true" \
&& terraform validate
```

Expected result: Terraform initializes the dev remote backend and validates the
configuration.

Reason: local manual execution does not have the GitHub Actions OIDC token that
`use_oidc=true` needs. Local runs use the Azure CLI session with Microsoft Entra
ID instead, while CI uses GitHub OIDC.

Use `&& terraform validate` so validation only runs after backend
initialization succeeds. Running `terraform validate` after a failed init can
look successful if old `.terraform` metadata is still present locally.

For a local read-only preview after initialization, run:

```bash
export TF_VAR_subscription_id="$(az account show --query id -o tsv)"
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"

terraform plan -var-file=environments/dev/dev.tfvars.example
```

Expected result: Terraform reads the remote state and prints a plan for the dev
example values without applying changes.

Reason: `plan` verifies the local backend authentication path and provider
authentication path without creating, updating, or destroying Azure resources.
The `TF_VAR_*` values supply root module variables that are intentionally not
committed: the current subscription ID, your SSH public key, and the trusted
IPv4 CIDR for SSH.

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
