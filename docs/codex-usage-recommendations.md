# Codex Usage Recommendations

This note captures practical ways to use Codex while learning Terraform and Azure.

## Session Retrospectives

Create a short retrospective note at the end of each learning session. The goal is not to write a full report, but to preserve the decisions, commands, errors, and lessons that would otherwise be lost.

Suggested format:

File name:

```text
docs/sessions/YYYY-MM-DD-NN-topic.md
```

Use a two-digit sequence number after the date, such as `01` or `02`, so
multiple retrospectives from the same day stay in chronological order.

```markdown
# Session YYYY-MM-DD-NN: <topic>

## Goal

## What Changed

## Commands Run

## Errors Hit

## What I Learned

## Next Step
```

Good entries for this project include:

- Terraform commands that succeeded or failed
- Azure error messages and their root causes
- Why a particular Terraform variable or resource setting exists
- What was destroyed to avoid cost
- Follow-up questions for the next phase

## Let Codex Handle Repeatable Git Work

Codex can safely help draft and run routine Git workflows when the scope is clear.

Recommended requests:

- "Show me the current diff and propose a commit message."
- "Create a draft PR body from the current branch."
- "Tag this as phase N complete after verifying the branch is clean."
- "Create a new branch from latest main and add a small doc."

Good guardrails:

- Ask Codex to show `git status --short --branch` before committing.
- Keep each learning phase on its own branch.
- Use annotated tags for phase completion, for example `phase-1-complete`.
- Let Codex draft commands first when the action is easy to review.

Example phase completion flow:

```bash
git status --short --branch
git add README.md main.tf variables.tf outputs.tf
git commit -m "feat: complete phase 1 single VM"
git tag -a phase-1-complete -m "Phase 1 complete: single Azure Linux VM"
git push origin HEAD
git push origin phase-1-complete
```

## Add Project Instructions For Codex

If this repository will keep using Codex, keep stable project-specific preferences in `AGENTS.md`.

Useful content:

```markdown
# Repository Instructions

- Explain Terraform and Azure changes in learning-friendly terms.
- Prefer small phase-based changes over broad refactors.
- Before applying Terraform, show the exact commands and expected risk.
- Never print secrets, subscription-specific values, SSH keys, or local state contents.
- After successful apply, remind me to run `terraform destroy` unless the task needs resources to remain.
- For docs, include the command, the expected result, and the reason.
- At the end of each learning session, offer to create or update a short retrospective under `docs/sessions/`.
- Name retrospective files as `YYYY-MM-DD-NN-topic.md`, using a two-digit sequence number after the date.
- Do not read all retrospectives by default. Read the latest one only when the user asks to continue from the previous session or when context is unclear.
```

Keep this file short. The best instructions are stable preferences, not a transcript of one session.

## Use Code Reading As A Learning Tool

Ask Codex to walk through the Terraform in small slices.

Good prompts:

- "Explain `main.tf` resource dependencies in apply order."
- "Which values are known at plan time and which are known after apply?"
- "Explain why the NSG rule references `allowed_ssh_cidr`."
- "Show how Terraform state relates to the Azure resources created here."

This is especially useful before moving from a working example to modules or multiple environments.

## Practice Failure Intentionally

Breaking a small local branch on purpose is a good way to learn Terraform diagnostics.

Safe experiments:

- Set `allowed_ssh_cidr` to an invalid CIDR and run `terraform plan`.
- Remove a required variable value and inspect the error.
- Change a resource name and inspect the planned replacement.
- Run `terraform validate` after introducing a syntax error.

Rules for experiments:

- Use a throwaway branch.
- Prefer `terraform validate` and `terraform plan` before `terraform apply`.
- If using `apply`, destroy resources immediately after the experiment.
- Do not commit broken code unless the commit is explicitly documenting a failure case.

## Keep A Command Log

For each phase, maintain a small command log in the retrospective or README.

Include:

- Setup commands
- Terraform commands
- Azure CLI checks
- SSH test commands
- Cleanup commands

This makes the learning path reproducible and makes future errors easier to compare against known-good output.

## Recommended Next Codex Workflow

For the next phase, use this loop:

1. Ask Codex to read the current Terraform and summarize the existing architecture.
2. Ask for a small implementation plan for the next phase.
3. Let Codex make the change on a feature branch.
4. Run `terraform fmt`, `terraform validate`, and `terraform plan`.
5. Review the plan together before applying.
6. After apply, test the resource behavior and destroy if it is only for learning.
7. Ask Codex to write the session retrospective and draft the commit, PR, and tag commands.
