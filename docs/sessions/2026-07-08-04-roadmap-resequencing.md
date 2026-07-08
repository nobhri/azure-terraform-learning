# Session 2026-07-08-04: Roadmap Resequencing

## Goal

Refine the post-Phase 2 roadmap so each future phase has one clear learning
goal, then leave enough planning context for Phase 3 and Phase 4 to be picked
up in a later session.

## What Changed

- Split the old combined Phase 3 into:
  - Phase 3: Remote Backend
  - Phase 4: GitHub Actions Foundation
- Moved Modules to Phase 5.
- Added data-platform-relevant Azure topics:
  - Phase 6: Identity And RBAC
  - Phase 7: Private Connectivity And DNS
  - Phase 8: Network Control
- Split CI/CD work into:
  - Phase 9: GitHub Actions Plan
  - Phase 10: Controlled Apply
- Updated the README phase list.
- Added implementation planning docs for Phase 3 and Phase 4.
- Linked the Phase 3 and Phase 4 plans from the roadmap.

## Key Learning

Remote backend and GitHub Actions are related, but they are different learning
goals.

Remote backend answers:

- Where does Terraform state live?
- How are `dev`, `staging`, and `prod` state files separated?
- How does shared state and locking reduce operator mistakes?

GitHub Actions foundation answers:

- How does a clean CI runner authenticate to Azure?
- How does OIDC avoid storing a long-lived Azure client secret?
- Which low-risk Terraform checks can run before adding plan and apply
  automation?

Keeping those topics separate makes the progression easier to understand and
review.

## Roadmap Decision

The roadmap now uses consecutive phase numbers instead of subphases such as
`3a` and `3b`.

Reason: each future topic is large enough to stand alone. Consecutive phase
numbers make tags, PR names, and progress tracking simpler:

- `phase-3-complete`
- `phase-4-complete`
- `phase-5-complete`

Subphases would be more useful if the work were one large deliverable split
into implementation chunks. In this repository, remote state, GitHub Actions,
modules, identity, private DNS, network control, plan automation, and controlled
apply are distinct learning goals.

## User Context Captured

The learning path should support a Data Engineer / Data Platform Engineer who
works mainly with Azure Databricks and wants enough Terraform and Azure admin
understanding to read infrastructure code, discuss design with platform/admin
teams, and make small Terraform changes.

Because of that goal, the roadmap prioritizes:

- remote state before automation
- OIDC basics before CI plan/apply
- modules before deeper infrastructure changes
- identity and RBAC before private connectivity
- private endpoints and DNS before route and egress control
- plan automation before controlled apply

This ordering keeps the learning path close to Databricks and data platform
conversations without turning the repository into a full Terraform operations
curriculum too early.

## Phase 3 Plan Summary

Phase 3 should focus only on Azure Blob Storage remote backend.

Planned scope:

- Change `backend "local"` to `backend "azurerm"`.
- Update environment `backend.hcl` files for Azure Blob Storage.
- Use one Storage Account and Container with separate keys:
  - `dev/terraform.tfstate`
  - `staging/terraform.tfstate`
  - `prod/terraform.tfstate`
- Add a Phase 3 guide with Azure CLI backend bootstrap commands.
- Do not add GitHub Actions in this phase.

Detailed plan:
[Phase 3 Remote Backend Plan](../plans/phase-3-remote-backend-plan.md)

## Phase 4 Plan Summary

Phase 4 should introduce GitHub Actions only as a validation runner.

Planned scope:

- Add `.github/workflows/terraform.yml`.
- Configure OIDC permissions.
- Use Azure login with GitHub repository variables.
- Run `terraform fmt -check`, `terraform init`, and `terraform validate`.
- Do not add `terraform plan` or `terraform apply` in this phase.

Detailed plan:
[Phase 4 GitHub Actions Foundation Plan](../plans/phase-4-github-actions-foundation-plan.md)

## Verification

- Confirmed the old broad phase names no longer appear in README or roadmap.
- Confirmed README and roadmap list the same phase sequence.
- Confirmed Phase 3 and Phase 4 plan documents exist and are linked from the
  roadmap.
- No Terraform commands were needed because this was a documentation-only
  session.

## Next Step

Commit and push the roadmap and planning docs, then open a draft PR. After that
PR is merged, start Phase 3 from the remote backend plan.
