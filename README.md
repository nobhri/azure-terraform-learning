# Azure Terraform Learning

This repository documents a step-by-step journey to learn Terraform on Azure.

The learning path is intentionally incremental. Each phase introduces only the
concepts added since the previous phase, instead of aiming for the final
architecture from the beginning.

## Current Focus

Phase 1 creates the minimum Azure infrastructure needed to run and reach one
Linux VM over SSH.

Start here:

- [Phase 1 guide](docs/phase-1-azure-minimum-configuration.md)
- [Roadmap](docs/roadmap.md)

## Phases

- Phase 0: Repository Setup
- Phase 1: Azure Minimum Configuration
- Phase 2: Multiple Environments
- Phase 3: Remote Backend and GitHub Actions
- Phase 4: Modules
- Phase 5: Advanced Network Design
- Phase 6: CI/CD Improvements

## Safety Notes

- Do not commit `terraform.tfstate`, `terraform.tfstate.backup`, local
  `.tfvars`, SSH private keys, or local environment files.
- Do not paste subscription-specific values, SSH keys, or Terraform state
  contents into chat.
- Destroy learning resources after a successful apply unless you intentionally
  need them to remain.
