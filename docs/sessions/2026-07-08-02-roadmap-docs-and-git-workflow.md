# Session 2026-07-08-02: Roadmap Docs And Git Workflow

## Goal

Update the Terraform learning roadmap so it matches the real Azure Phase 1
resource model, then keep the repository documentation and Git workflow easy to
follow.

The `-02` suffix is used because another retrospective already exists for
2026-07-08. This keeps same-day session files sorted in the order they happened.

## What Changed

- Updated the roadmap so Phase 1 includes the real minimum Azure VM dependency
  graph: Resource Group, VNet, Subnet, NIC, NSG, optional Public IP, and Linux
  VM.
- Moved the detailed roadmap out of `README.md` and into `docs/roadmap.md`.
- Moved Phase 1 commands and troubleshooting out of `README.md` and into
  `docs/phase-1-azure-minimum-configuration.md`.
- Added a Phase 1 source snapshot link based on the `phase-1-complete` Git tag:
  <https://github.com/nobhri/azure-terraform-learning/tree/phase-1-complete>
- Kept `README.md` as a short entry point with the current focus, phase list,
  key doc links, and safety notes.
- Updated `AGENTS.md` to make Git branch checks explicit before editing,
  moving changes, staging, committing, or pushing.

## Git Workflow Correction

The first roadmap edit was made on a branch from a previous session. That was
corrected by:

1. Stashing the README change.
2. Switching to `main`.
3. Pulling latest `origin/main` with `git pull --ff-only origin main`.
4. Creating a new branch, `codex-update-learning-roadmap`.
5. Re-applying the stashed README change on the new branch.

The follow-up `AGENTS.md` update now makes this branch check explicit so future
work starts by confirming whether the current branch matches the current task.

## Commands Run

```bash
git status --short --branch
git diff -- README.md
git stash push -m roadmap-readme-update -- README.md
git switch main
git pull --ff-only origin main
git switch -c codex-update-learning-roadmap
git stash pop
git add README.md
git commit -m "docs: update Terraform learning roadmap"
git push -u origin codex-update-learning-roadmap
git add README.md docs/roadmap.md docs/phase-1-azure-minimum-configuration.md
git diff --cached --check
git commit -m "docs: split detailed guides from README"
git push
git add AGENTS.md
git commit -m "docs: clarify git workflow checks"
git push
```

## Verification

- Confirmed the branch was created from latest `main`.
- Confirmed only task-related files were staged for each commit.
- Ran `git diff --cached --check` for the documentation split.
- Confirmed the working tree was clean after each push.

No Terraform runtime validation was needed because the changes were
documentation-only.

## What I Learned

- Phase 1 documentation should describe the real Azure VM minimum, not a
  simplified "single VM" abstraction.
- `README.md` should stay as the repository entry point. Longer learning
  material belongs under `docs/`.
- Same-day retrospectives need an ordering convention. A suffix like `-02`
  keeps chronological order clear without relying on commit history.
- Git instructions need an explicit "before editing" branch check, not only a
  "before committing" check.

## Next Step

Open a draft PR from `codex-update-learning-roadmap` to `main`. The PR should
state that this was documentation-only work and no Terraform apply or destroy
was run.
