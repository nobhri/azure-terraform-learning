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

## Task-specific Workflows

- Before any Git or pull request work, read and follow
  [Git and PR Workflow](docs/agent-guides/git-and-pr-workflow.md).
- Before adding or reorganizing learning documentation, read and follow
  [Learning Documentation Workflow](docs/agent-guides/learning-documentation-workflow.md).
