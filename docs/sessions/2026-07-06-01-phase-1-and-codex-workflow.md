# Session 2026-07-06-01: Phase 1 And Codex Workflow

## Goal

Complete Phase 1 validation for a single Azure Linux VM and improve the repository workflow for future Codex-assisted learning sessions.

## What Changed

- Confirmed the Phase 1 Terraform flow works end to end:
  - `terraform apply`
  - `terraform output`
  - SSH connection to the VM
  - `terraform destroy`
- Documented the IPv4 versus IPv6 SSH CIDR issue in the README.
- Added `allowed_ssh_cidr` validation so invalid IPv4 CIDR input is caught earlier.
- Added Codex usage recommendations under `docs/`.
- Added repository-level Codex instructions in `AGENTS.md`.

## Commands Run

```bash
terraform plan
terraform apply
terraform output
ssh azureuser@$(terraform output -raw public_ip_address)
terraform destroy
git status --short --branch
git pull --ff-only
git switch -c codex-usage-recommendations
git add AGENTS.md docs/codex-usage-recommendations.md
git commit -m "docs: add Codex repository instructions"
git push -u origin codex-usage-recommendations
```

## Errors Hit

### Azure NSG IPv6 CIDR Error

`terraform apply` failed while creating the Network Security Group:

```text
SecurityRuleInvalidAddressPrefix: ... invalid Address prefix. Value provided: 2400:.../32
```

Root cause:

- `curl ifconfig.me` returned an IPv6 address.
- The value was used as `TF_VAR_allowed_ssh_cidr` with `/32`.
- This Phase 1 VM uses an IPv4 public IP configuration, so the SSH source CIDR should be an IPv4 `/32`.

Fix:

```bash
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"
```

Fallback:

```bash
export TF_VAR_allowed_ssh_cidr="$(curl -s https://api.ipify.org)/32"
```

### Terraform Provider Validation Issue In Sandbox

`terraform validate` failed in the Codex sandbox while loading the AzureRM provider schema. This appeared to be an environment/plugin execution issue, not a Terraform configuration issue.

## What I Learned

- `terraform plan` can look fine even when Azure rejects a provider-side API request during `apply`.
- Public IP lookup commands may return IPv6 depending on the local network and endpoint behavior.
- For this phase, SSH source access should be constrained to a public IPv4 address with `/32`.
- `AGENTS.md` is the right place for stable repository instructions that Codex should apply in future sessions.
- Session retrospectives should live under `docs/sessions/`, but Codex should not read every retrospective by default.

## Next Step

- Open a draft PR for the Codex workflow documentation branch.
- For Phase 2, start from latest `main`, read the current Terraform architecture, and plan the multi-environment structure before editing code.
