# Azure Terraform Learning

This repository documents a step-by-step journey to learn Terraform on Azure.

The learning path is intentionally incremental. Each phase introduces only the
concepts added since the previous phase, instead of aiming for the final
architecture from the beginning.

## Current Focus

Phase 5's module refactor is implemented, with a separate root module for each
environment. Its planned `phase-5-complete` tag is still pending. Phase 6
(Identity and RBAC) is the next planned implementation phase.

Start here:

### Current

- [Phase 5 guide](docs/phase-5-modules.md)
- [Phase 6 plan](docs/plans/phase-6-identity-rbac-plan.md)
- [Roadmap and phase status](docs/roadmap.md)

### Foundation Phases

- [Phase 1: Azure Minimum Configuration](docs/phase-1-azure-minimum-configuration.md)
- [Phase 2: Multiple Environments](docs/phase-2-multiple-environments.md)
- [Phase 3: Remote Backend](docs/phase-3-remote-backend.md)
- [Phase 4: GitHub Actions Foundation](docs/phase-4-github-actions-foundation.md)

### Reference

- [Phase 5 implementation plan](docs/plans/phase-5-modules-plan.md)
- [Retrospective through Phase 4](docs/start-through-phase-4-retrospective.md)
- [Mistake prevention notes](docs/mistake-prevention.md)
- [Codex usage recommendations](docs/codex-usage-recommendations.md)

The roadmap is the source of truth for phase status and links to completed
tagged versions.

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
