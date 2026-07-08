# Repository Instructions

Use these instructions for this repository unless the user gives a more specific request.

## Project Context

- This repository is for learning Terraform on Azure through small phase-based changes.
- Prefer clear, incremental examples over broad refactors.
- Explain Terraform and Azure decisions in learning-friendly terms, but keep final answers concise.
- When adding docs, include the command, the expected result, and the reason when useful.

## Safety

- Never print secrets, SSH private keys, Terraform state contents, or subscription-specific values unless the user explicitly asks and the value is already visible in the conversation.
- Do not commit `terraform.tfstate`, `terraform.tfstate.backup`, local `.tfvars`, or other local environment files.
- Remind the user to destroy learning resources after a successful apply unless the task requires resources to remain.
- Never run `terraform apply` or `terraform destroy` without an explicit user request.

## Terraform Workflow

- Prefer this validation order for Terraform changes:
  1. `terraform fmt`
  2. `terraform validate`
  3. `terraform plan`
- If a Terraform command fails, explain the likely root cause and the smallest next command to verify it.
- Before suggesting `apply`, summarize what the plan is expected to create, update, or destroy.
- Keep Terraform changes scoped to the current learning phase unless the user asks for a larger redesign.

## Git Workflow

- Before making or moving changes, always run `git status --short --branch`.
- Before editing, confirm whether the current branch matches the current task, whether it contains work from a previous session, whether there are existing uncommitted changes, and which files are safe to edit, stage, or commit.
- Use a new feature branch for each independent task or session. Do not continue work on a branch from a previous session unless the user explicitly asks to amend that branch.
- If the current branch is from a previous task, keep current changes safe with `git stash`, switch to latest `main`, pull with `git pull --ff-only origin main`, create a new feature branch, then re-apply the changes.
- Before committing, always run `git status --short --branch` and inspect the diff.
- Before committing, inspect both unstaged and staged changes with `git diff` and `git diff --cached`.
- Stage only files related to the requested task. Do not use broad staging when the worktree contains unrelated changes.
- Use feature branches. Never commit directly to `main`.
- Use `main` as the default PR base unless the user specifies another branch.
- Open draft PRs by default.
- Never force push.
- For phase completion, prefer annotated tags, for example `phase-1-complete`.

## PR Workflow

- PR descriptions should include:
  - what changed
  - why it changed
  - how it was verified
  - any remaining risk or follow-up
- For documentation-only changes, state that no runtime validation was needed.
- For Terraform changes, include the Terraform commands that were run and whether Azure resources were applied or destroyed.
- When using `gh` for PR work, do not treat sandboxed authentication or network
  failures as the final state. GitHub API commands such as `gh auth status`,
  `gh pr list`, `gh pr view`, and `gh pr create` may need normal local
  environment access to read keychain credentials and reach the API. If a
  sandboxed `gh` command reports an invalid token or API connectivity failure,
  retry the same `gh` command with the required permission instead of asking
  the user to re-authenticate first.

## Learning Workflow

- Offer code-reading prompts when they help the user understand the next Terraform concept.
- It is acceptable to suggest safe failure experiments on throwaway branches, using `terraform validate` or `terraform plan` before `apply`.
- When a real error occurs, capture the error pattern and fix in README or a session retrospective if it is likely to help later.
- At the end of each learning session, offer to create or update a short retrospective under `docs/sessions/`.
- Name retrospective files as `YYYY-MM-DD-NN-topic.md`, where `NN` is a two-digit sequence number for that date, for example `2026-07-08-01-phase-1-networking.md`.
- Do not read all retrospectives by default. Read the latest one only when the user asks to continue from the previous session or when context is unclear.
