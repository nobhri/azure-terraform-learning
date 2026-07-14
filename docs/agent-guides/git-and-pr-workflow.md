# Git and PR Workflow

Use this guide for Git operations and pull request work in this repository.

## Starting Work

- Before making or moving changes, run `git status --short --branch`.
- Confirm that the current branch matches the task, whether it contains work
  from a previous session, whether there are uncommitted changes, and which
  files are safe to edit, stage, or commit.
- Use a new feature branch for each independent task or session. Do not continue
  work on a previous session's branch unless the user explicitly asks to amend
  it.
- If the current branch belongs to a previous task, preserve its changes with
  `git stash`, switch to `main`, run `git pull --ff-only origin main`, create a
  new feature branch, and then reapply the changes.

## Committing and Tagging

- Never commit directly to `main` and never force push.
- Before committing, run `git status --short --branch` and inspect both
  `git diff` and `git diff --cached`.
- Stage only task-related files. Do not use broad staging when unrelated changes
  are present.
- Prefer annotated phase-completion tags, such as `phase-1-complete`.

## Pull Requests

- Use `main` as the default base and open draft pull requests unless the user
  specifies otherwise.
- Prefer the GitHub CLI (`gh`). Check `gh auth status` before inspecting or
  creating a pull request, and use `gh pr view`, `gh pr diff`, and
  `gh pr checks` for inspection.
- Create draft pull requests with `gh pr create --draft` after pushing the
  feature branch.
- Treat GitHub connector tools as a fallback or supplement to `gh`.
- If a sandboxed `gh` command reports invalid authentication or API
  connectivity, retry it with the required local permissions before asking the
  user to run `gh auth login -h github.com`.

Every pull request description should state:

- what changed
- why it changed
- how it was verified
- remaining risks or follow-up work

For documentation-only changes, state that runtime validation was unnecessary.
For Terraform changes, list the Terraform commands run and say whether Azure
resources were applied or destroyed.
