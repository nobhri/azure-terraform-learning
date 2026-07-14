# Learning Documentation Workflow

Use this guide when recording or reorganizing learning material.

- Offer code-reading prompts when they help explain the next Terraform concept.
- Safe failure experiments may be suggested on throwaway branches, using
  `terraform validate` or `terraform plan` before any apply.
- Record a real error pattern and its fix in the README or a session
  retrospective when it is likely to be useful later.
- At the end of a learning session, offer to create or update a short
  retrospective under `docs/sessions/`.
- Name retrospective files `YYYY-MM-DD-NN-topic.md`, where `NN` is a two-digit
  sequence for that date, for example
  `2026-07-08-01-phase-1-networking.md`.
- Do not read every retrospective by default. Read only the latest one when the
  user asks to continue from the previous session or when context is unclear.

## Roadmap Maintenance

Treat [the roadmap](../roadmap.md) as the source of truth for phase status.
Update its progress table in the same change when:

- implementation starts: set the phase to `In progress`
- implementation reaches `main`: set the phase to `Implemented` and identify
  any remaining completion step
- a completion tag is created: set the phase to `Complete` and link directly to
  that tagged repository version

Also update the roadmap's `Last reviewed` date and keep the README's current
focus consistent with the next planned work.
