# Session 2026-07-08-03: Phase 2 Environments

## Goal

Implement Phase 2 by separating the Phase 1 Terraform configuration into
`dev`, `staging`, and `prod` environments while keeping local state.

## What Changed

- Added environment directories under `environments/`.
- Added one local backend config per environment.
- Added committed `.tfvars.example` files for `dev`, `staging`, and `prod`.
- Updated `.gitignore` so real `.tfvars` files stay local.
- Added the Phase 2 guide.
- Updated the README current focus from Phase 1 to Phase 2.

## Key Learning

`.tfvars` files and backend configuration do different jobs.

The `.tfvars` file changes the input values used by the Terraform code. In this
phase, that means environment-specific names and tags, such as
`terraform-learning-dev` or `environment = "staging"`.

The backend config changes where Terraform stores state. In this phase, that
means separate local state files such as
`environments/dev/terraform.tfstate`.

Both are needed for environment separation:

- `.tfvars` separates the intended resource names and tags.
- backend config separates the resource records Terraform uses for planning.

## Questions Clarified

`terraform init` is needed again when switching from one environment backend to
another. For example, after working in prod, dev work should start with:

```bash
terraform init -reconfigure -backend-config=environments/dev/backend.hcl
```

`init` does more than select a state file. It also prepares providers, checks
the lock file, and initializes modules when modules exist. In Phase 2, the state
path selection is simply the most visible part.

`terraform fmt` does not technically need to run after `init`. It only formats
Terraform files and does not read state or provider schemas. It can run before
`init`; the guide keeps it after backend selection so the environment workflow
is easy to follow.

`terraform validate` checks whether the Terraform configuration is valid, using
provider schemas. It does not verify state drift or compare against Azure
resources. `terraform plan` is the command that compares configuration, state,
and real infrastructure.

Phase 2 is intentionally not a production-ready workflow. It has manual footguns
such as forgetting `-var-file` or pairing the wrong backend with the wrong
variable file. Later phases add guardrails through remote state, GitHub Actions,
module-based environment wrappers, CI checks, and approval boundaries.

The committed `.tfvars.example` files are a learning choice, not a strict
technical requirement. The current environment values are not secret, so real
committed `.tfvars` files would also work and would make the commands shorter.
The example-file approach keeps the pattern that templates belong in Git while
local environment files stay local, which leaves room for future values that may
be environment-specific or sensitive.

## Understanding Review

Strong points:

- You correctly connected `variables.tf` defaults and `.tfvars` overrides. That
  is the core Terraform variable model: defaults provide baseline behavior, and
  environment files override only the parts that differ.
- You noticed that backend selection and variable selection can drift apart.
  That is a practical infrastructure concern, not just a syntax detail.
- You challenged whether `.tfvars.example` was necessary when the current values
  are not secret. That is the right kind of tradeoff question because it weighs
  safety habits against workflow simplicity.
- You tested `plan`, `apply`, and `destroy` across all three environments
  instead of trusting the directory structure alone. That confirms the state and
  variable boundaries with real Terraform behavior.

Weak points to reinforce:

- `terraform init` can feel like it only selects a state file in this phase, but
  it also prepares providers, lock-file state, and modules. Keep the broader
  meaning in mind before Phase 3 and Phase 4.
- `terraform validate` is easy to overinterpret. It validates configuration
  shape and provider schema usage, but it does not prove Azure resources match
  the configuration. Use `plan` for that comparison.
- Local backend workflows depend heavily on the operator remembering the active
  backend. That is why manual `init` plus manual `-var-file` is a learning
  workflow, not a strong operating model.
- `.tfvars` files are not automatically sensitive. The decision to commit them
  should be based on what they contain and how the team wants to manage local
  differences.

Next concepts to watch:

- Remote state and locking: how shared state prevents two operators or CI jobs
  from writing conflicting changes.
- Environment wrappers: how `cd environments/dev && terraform plan` can reduce
  backend and variable mismatch compared with root-level commands.
- CI plan boundaries: how GitHub Actions can make `dev`, `staging`, and `prod`
  explicit workflow targets instead of manually typed command combinations.
- Approval boundaries: why production applies should have an extra human or
  platform-level gate even when the Terraform code is valid.

## Mistake Captured

During Phase 2 testing, it is possible to initialize the dev backend correctly
but accidentally run `terraform apply` without `-var-file`.

In that case, Terraform uses the dev state path but the defaults from
`variables.tf`. The cleanup should use the same active backend and no
`-var-file`:

```bash
terraform init -reconfigure -backend-config=environments/dev/backend.hcl
terraform plan -destroy
terraform destroy
```

After cleanup, rerun the environment-specific flow:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
terraform apply -var-file=environments/dev/dev.tfvars
terraform destroy -var-file=environments/dev/dev.tfvars
```

## Verification

- `terraform fmt -recursive` succeeded.
- `terraform validate` succeeded.
- `git check-ignore` confirmed real environment `.tfvars` files are ignored.
- Dev plan, apply, and destroy were confirmed manually by the user.
- Staging plan, apply, and destroy were confirmed manually by the user.
- Prod plan, apply, and destroy were confirmed manually by the user.

## Next Step

Inspect the final diff, commit the Phase 2 changes, and push the branch. Open a
draft PR when requested.
