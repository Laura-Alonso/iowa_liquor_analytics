---
name: audit
description: Check the repo's full git history for keys, tokens and personal information, and show what would be pushed. Use when the user runs /audit or asks for a security check before pushing.
---

# Audit the repo before pushing

This repo is **public**. This skill only reports: do not commit, push, or change
any file.

## 1. See what would be published

- Run `git status --short --branch`.
- Run `git log --format='%h %s' origin/main..HEAD` and
  `git diff --stat origin/main HEAD`.

## 2. Run the audit

Run `scripts/audit_history.sh` with no arguments, with a timeout of 5 minutes.
It reads the email to search for from the `AUDIT_EMAIL` environment variable.

Never write the user's email in a command, a file or the report. If the output
says `Given email: skipped`, tell the user that search did not run and that they
can set `AUDIT_EMAIL` in their shell profile.

## 3. Report back

Exit codes: 0 = clean, 1 = something found, 2 = the audit itself failed.

- Exit 2 means there is **no result**. Say so, and never describe it as clean.
- Exit 1: list what was found and in which commit, without repeating the matched
  value. Recommend not pushing until it is resolved.
- Exit 0: say it is clean, and that both controls passed.

Always include:

- The commits that would be pushed, or that there are none.
- Any uncommitted or untracked files, with a warning that the audit reads
  commits only, so it has not checked them.
- The limit: the audit recognizes known patterns, so a clean result is not a
  guarantee. It would not catch something like a home address in plain text.

End by asking whether the user wants to push. Push only if they say yes.
