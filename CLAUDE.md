# CLAUDE.md

## About me
- Analytics engineer learning Claude Code, dbt and AI-assisted workflows.
- I'm still learning technical terms: explain new concepts briefly,
  with a concrete example.
- Mac with Spanish keyboard.

## How to work with me
- Before running a command, explain in one sentence what it does and why.
- Work in small steps; don't do more than I asked.
- If you're unsure about data meaning or a definition, ask — don't guess.

## Automation first
- Everything must be reproducible from code. No manual-only steps:
  if something was done by hand (e.g. in the BigQuery console),
  save it as a script in the repo.
- If a task is likely to repeat, propose how to automate it
  (script, dbt macro, Claude Code skill, hook) before doing it manually
  a second time.
- Prefer commands that are safe to re-run (idempotent):
  running them twice gives the same result, not duplicates or errors.
- When you finish a task, suggest one thing that could be automated next.

## Tools
- Python: use uv (never plain pip). Run tools with `uv run`.
- Warehouse: BigQuery sandbox, project ID `iowa-liquor-lab`.
- dbt v2 (PyPI package `dbt`; BigQuery support is built in, no separate
  adapter package). Editor: VS Code.

## Project rules
<!-- To be completed after the dbt project is created (/init) -->