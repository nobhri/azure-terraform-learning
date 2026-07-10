# Terraform Learning Roadmap

This roadmap keeps the learning path incremental and Azure-first while avoiding
Azure-only structure where possible. Environment directories, modules, and CI
boundaries should stay portable enough that an AWS version can later follow the
same shape with provider-specific resources swapped underneath.

After Phase 2, the roadmap was refined so each later phase has one primary
learning goal. This keeps remote state, automation, modules, identity,
networking, and controlled deployment separate enough to learn and review one
concept at a time.

## Phase 0: Repository Setup

Create the repository foundation before adding infrastructure.

What this adds:

- GitHub repository
- README
- `.gitignore`
- Branch protection
- Initial commit

Why this phase is needed:

Terraform work should start from a safe Git workflow because infrastructure
changes are easier to review when each phase is small and traceable. Branch
protection also sets the habit that infrastructure changes should go through
review instead of being pushed directly to `main`.

## Phase 1: Azure Minimum Configuration

Create the smallest useful Azure Linux VM configuration with Terraform.

What this adds:

- Resource Group
- Virtual Network
- Subnet
- Network Interface
- Public IP, if SSH access from the internet is needed
- Network Security Group
- Linux Virtual Machine

Concepts learned:

- Provider
- Resource
- Variable
- Output
- Local backend
- `terraform plan`
- `terraform apply`
- `terraform destroy`
- `terraform state`

Why this phase is needed:

Azure does not create a Linux VM as a standalone object. A VM needs a NIC, the
NIC needs a subnet, and the subnet needs a virtual network. NSG and Public IP
resources are added only to make SSH access explicit and controlled. This phase
therefore teaches the real minimum dependency graph for an Azure VM while still
keeping all Terraform state local and easy to inspect.

## Phase 2: Multiple Environments

Split the working Phase 1 configuration into separate environments.

What this adds:

- `dev`
- `staging`
- `prod`
- `.tfvars` usage
- Environment-specific local state
- Environment directory structure

Why this phase is needed:

Most infrastructure code must represent more than one environment. This phase
adds only environment separation while keeping the backend local, so the new
lesson is how variables, directory layout, and state boundaries prevent `dev`,
`staging`, and `prod` from accidentally sharing the same resources.

## Phase 3: Remote Backend

Move state from local files to Azure Blob Storage.

What this adds:

- Azure Blob Storage remote backend
- Remote state
- State locking
- Environment-specific remote state keys
- Backend bootstrap documentation

Implementation plan: [Phase 3 Plan](plans/phase-3-remote-backend-plan.md)

Why this phase is needed:

Local state is useful for learning, but shared Terraform work needs a common
state location and locking. Azure Blob Storage becomes the remote backend while
the existing `dev`, `staging`, and `prod` state boundaries remain visible
through separate backend keys. This phase focuses only on where Terraform state
lives before introducing CI automation.

## Phase 4: GitHub Actions Foundation

Introduce GitHub Actions as a Terraform validation runner.

What this adds:

- GitHub Actions workflow
- OIDC authentication from GitHub to Azure
- Federated credential setup documentation
- `terraform fmt -check`
- `terraform init`
- `terraform validate`

Implementation plan: [Phase 4 Plan](plans/phase-4-github-actions-foundation-plan.md)

Why this phase is needed:

GitHub Actions runners start from a clean environment, so they need explicit
authentication, backend configuration, and Terraform setup. This phase teaches
how GitHub can authenticate to Azure without a stored client secret and how CI
can run low-risk checks. It does not add automated `terraform plan` or
`terraform apply`; those are separate deployment workflow topics.

Retrospective through Phase 4:
[Start Through Phase 4 Retrospective](start-through-phase-4-retrospective.md)

Mistake prevention notes:
[Mistake Prevention Notes](mistake-prevention.md)

## Phase 5: Modules

Refactor VM and network code into modules after the non-module version is
understood.

What this adds:

- Module
- Input variable
- Output
- Module design
- Environment wrappers that call modules

Implementation plan: [Phase 5 Plan](plans/phase-5-modules-plan.md)

Why this phase is needed:

Modules are easier to design after the direct resources are already working.
This phase keeps the Azure resources mostly the same and changes the code shape:
environment directories become thin wrappers, while reusable VM and network
logic moves into modules. This mirrors Terraform best practice by separating
environment configuration from reusable infrastructure building blocks without
introducing that abstraction too early.

## Phase 6: Identity And RBAC

Add Azure identity and access control concepts used by data platform resources.

What this adds:

- Managed identity
- User-assigned managed identity
- Role assignment
- Scope boundaries
- Storage Account access through RBAC

Implementation plan: [Phase 6 Plan](plans/phase-6-identity-rbac-plan.md)

Why this phase is needed:

Azure Databricks and data platform designs often depend on managed identity,
RBAC, and clear scope boundaries. This phase adds those concepts before private
connectivity so access decisions are understood separately from network
reachability. The goal is to make small Terraform changes to identity and
permissions with a clear understanding of who can access what.

## Phase 7: Private Connectivity And DNS

Add private access patterns used by Azure data platform services.

What this adds:

- Private Endpoint
- Private DNS Zone
- DNS zone virtual network link
- Storage Account private access
- Key Vault private access
- Public network access settings

Why this phase is needed:

Private endpoints and private DNS are common sources of confusion in Azure data
platform work. A private endpoint changes network reachability, but private DNS
controls how clients resolve service names. This phase makes that relationship
explicit and connects the VM-based learning environment to patterns used around
Databricks, Storage Accounts, and Key Vault.

## Phase 8: Network Control

Extend the minimal Phase 1 network into explicit routing, ingress, and egress
design.

What this may add:

- Network Security Group design
- Route Table
- NAT Gateway
- Bastion
- Public IP removal or reduction
- Egress control

Why this phase is needed:

Phase 1 includes networking only because a VM cannot run without it and SSH
needs controlled access. This phase changes the goal: the focus is no longer
"networking required to run a VM", but "networking as an Azure architecture
topic". Routing, controlled ingress, private administration, and egress design
can be learned after private connectivity and DNS are already understood.

## Phase 9: GitHub Actions Plan

Add pull request planning to the GitHub Actions workflow.

What this adds:

- `terraform plan` in CI
- Environment-specific plan commands
- Backend config and `.tfvars` pairing in workflows
- Plan artifacts or summaries
- Plan review practice

Why this phase is needed:

Being able to make Terraform changes safely requires reading plans before
applying them. This phase adds the plan step after remote backend, OIDC,
modules, identity, and networking basics are already in place. Keeping plan
automation separate from apply automation makes it easier to reason about what
the workflow can change and what it can only report.

## Phase 10: Controlled Apply

Add a guarded path for applying Terraform changes through GitHub Actions.

What this adds:

- Manual apply workflow
- GitHub Environments
- Environment protection
- Approval gates
- Clear apply and destroy boundaries

Why this phase is needed:

Applying Terraform changes is an operational responsibility, not just a CI
feature. This phase adds approvals and environment protection after the plan
workflow is already understood. The goal is to learn how teams control who can
change infrastructure and when, while keeping destructive actions explicit.
