---
name: diary
description: Update docs/diary.md with this session's steps, decisions and changes, and refresh its "Pick up here" section. Use when the user runs /diary or asks to update the project diary.
---

# Update the project diary

`docs/diary.md` is how work carries over between sessions. It is committed to a
**public** repo. Edit only that file, and do not commit or push unless asked.

## 1. Gather the facts

Read `docs/diary.md`, then check the repo:

- Run `git status --short --branch`.
- Find the newest commit in the diary's `### Commits` table, and run
  `git log --format='%h %s' <that-hash>..HEAD` to list newer commits.

Use this conversation and git as the only sources. If the conversation has no
detail on a commit, describe only what `git show --stat` proves.

## 2. Refresh "Pick up here"

Rewrite it so a new session could start from it alone:

- Set `Last updated` to today's date.
- **Current state:** update anything that changed.
- **Next steps:** the real next actions, in order.
- **Open items:** add new ones. Remove finished ones, and record them in the log.
- **Decided:** add decisions that should not be reopened without a reason.

## 3. Add to the log

Find the heading for today's date.

- If it exists, continue its numbered steps.
- If not, add `## YYYY-MM-DD: <short title>` after the last session, numbering from 1.

Add one `### N. <title>` per meaningful step, using only the labels that apply:

- **Did:** what was done.
- **Why** or **Decision:** the reasoning, including what was rejected.
- **Changed:** files affected.
- **Problem:** / **Fix:** what went wrong and how it was solved.
- **Verified:** how it was checked, and what was not checked.
- **Not done:** anything skipped or left unfinished.

Skip steps that are already logged. Don't log routine questions or status checks.

Add each newer commit from step 1 to that session's `### Commits` table, moving
the table to the end of the session if needed. Only list commits that already
exist. A commit that includes this diary update gets listed on the next run.

## 4. Rules

- Record only what happened. Never invent results, and say so if something
  was not verified.
- Keep failures in the log. They explain why things are the way they are.
- Keep entries to short bullets.
- Never write secrets, keys, tokens, or personal email addresses. Use the GitHub
  noreply address if an address is needed at all.

## 5. Report back

Tell the user which steps were added and what changed in "Pick up here". Remind
them that the diary is not committed yet, if that is the case.
