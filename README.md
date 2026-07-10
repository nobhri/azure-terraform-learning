# Azure Terraform Learning

This repository documents a step-by-step journey to learn Terraform on Azure.

The learning path is intentionally incremental. Each phase introduces only the
concepts added since the previous phase, instead of aiming for the final
architecture from the beginning.

## Current Focus

Phase 4 adds GitHub Actions as a low-risk Terraform validation runner after the
Azure Blob Storage remote backend is in place.

Start here:

- [Phase 4 guide](docs/phase-4-github-actions-foundation.md)
- [Retrospective through Phase 4](docs/start-through-phase-4-retrospective.md)
- [Mistake prevention notes](docs/mistake-prevention.md)
- [Phase 5 plan](docs/plans/phase-5-modules-plan.md)
- [Phase 6 plan](docs/plans/phase-6-identity-rbac-plan.md)
- [Phase 3 guide](docs/phase-3-remote-backend.md)
- [Phase 2 guide](docs/phase-2-multiple-environments.md)
- [Phase 1 guide](docs/phase-1-azure-minimum-configuration.md)
- [Roadmap](docs/roadmap.md)

## Phases

- Phase 0: Repository Setup
- Phase 1: Azure Minimum Configuration
- Phase 2: Multiple Environments
- Phase 3: Remote Backend
- Phase 4: GitHub Actions Foundation
- Phase 5: Modules
- Phase 6: Identity And RBAC
- Phase 7: Private Connectivity And DNS
- Phase 8: Network Control
- Phase 9: GitHub Actions Plan
- Phase 10: Controlled Apply

## Safety Notes

- Do not commit `terraform.tfstate`, `terraform.tfstate.backup`, local
  `.tfvars`, SSH private keys, or local environment files.
- Do not paste subscription-specific values, SSH keys, or Terraform state
  contents into chat.
- Destroy learning resources after a successful apply unless you intentionally
  need them to remain.
