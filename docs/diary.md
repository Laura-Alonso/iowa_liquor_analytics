# Project diary

A log of what was done, why, and what is still open. Newest session last.
Read **Pick up here** first when resuming work.

## Pick up here

_Last updated: 2026-11-09_

**Current state**
- Repo: <https://github.com/Laura-Alonso/iowa_liquor_analytics> (public), branch `main`.
- Environment: Python 3.12, uv, dbt 2.0.11, pre-commit 4.7.0, Google Cloud CLI 592.0.0
  (includes `bq` 2.1.41).
- BigQuery: sandbox project `iowa-liquor-lab`. The raw table was created by hand in
  the console and its SQL is saved in `scripts/create_raw_iowa_sales.sql`.
- Authentication: gcloud OAuth with Application Default Credentials (ADC). The
  credentials file is in `~/.config/gcloud/`, outside the repo.
- Session handoff: this diary, the session routine in `CLAUDE.md`, and the `/diary`
  skill in `.claude/skills/diary/SKILL.md`.
- The dbt project has **not** been created yet.

**Next steps**
1. Create the dbt project and `profiles.yml` (kept in `~/.dbt/`, never in the repo).
2. Run `dbt debug` to test the BigQuery connection for the first time.
3. Complete "Project rules" in `CLAUDE.md` once the dbt project exists.

**Open items**
- [ ] `scripts/create_raw_iowa_sales.sql` has never been run or validated as saved.
      It uses `create or replace table`, so running it overwrites `raw.iowa_sales`.
- [ ] `raw.iowa_sales` has a table expiration set. Decide how to keep the data past it.
      `scripts/check_raw_table.sh` shows the date and days left.
- [ ] Add `scripts/setup.sh` (`uv sync` + `uv run pre-commit install`) for fresh clones.
- [ ] Run `scripts/audit_history.sh` in GitHub Actions (decided, not built).
- [ ] Optional: in GitHub email settings, turn on "Keep my email addresses private"
      and "Block command line pushes that expose my email".
- [ ] Optional: set `user.name` explicitly in git; it currently comes from the Mac account.

**Decided: don't reopen without a reason**
- No pre-push hook for the audit: pre-commit and GitHub push protection cover this.
- The repo is public, and this diary stays public in it.
- Git commits use the GitHub noreply address, never a personal email.
- BigQuery authentication uses gcloud OAuth and ADC, with no service account keys.

---

## 2026-11-08: Project setup and public release

### 1. Python project with uv
- **Did:** initialized a bare uv project pinned to Python 3.12.
- **Why bare:** avoids sample files such as `main.py`.
- **Changed:** `pyproject.toml`, `.python-version`, `uv.lock`, `.venv/`.

### 2. dbt: installed v1, then moved to v2
- **Did:** installed `dbt-core` 1.12.6 and `dbt-bigquery` 1.12.2, then replaced both
  with `dbt` 2.0.11 after dbt's notice that v2 is the default for new projects.
- **Decision:** v2, because nothing had been built yet, so switching cost nothing.
- **Learned from the official docs:**
  - The v2 PyPI package is `dbt`.
  - BigQuery has no separate package. v2 uses ADBC drivers, downloaded on first run.
  - `dbt-oss` is the separate Apache 2.0 build and can't share an environment with `dbt`.
- **Result:** the environment went from 104 packages to 4.

### 3. Git and `.gitignore`
- **Did:** initialized git on `main` and added a `.gitignore` for Python/uv, dbt output
  and credentials.
- **Decision:** ignore specific key-file patterns rather than all `*.json`.
- **Decision:** ignore `profiles.yml`, since it can hold connection details.

### 4. Raw table saved as code
- **Did:** turned the manual console SQL into `scripts/create_raw_iowa_sales.sql`.
- **Idempotent:** `create schema if not exists` (location US) and `create or replace table`.
- **Decision:** cluster by `date` instead of partitioning, because the sandbox expires
  partitions after 60 days and sales go back to 2022.
- **Not done:** the script was not run, because the `bq` CLI isn't installed.

### 5. First commit and author email
- **Did:** updated `CLAUDE.md` to say dbt v2 and made the first commit.
- **Problem:** git had no email configured and used an auto-generated Mac address.
- **Fix:** set the email and amended the commit, before anything was pushed.

### 6. Pre-commit hook
- **Did:** added `pre-commit` as a uv dev dependency with `detect-private-key` (v6.0.0).
- **Why this check:** it reads file contents, so it catches a key under any filename.
- **Tested:** it blocked a fake service account key named `my-project-abc123.json`,
  a name `.gitignore` would not have caught.
- **Limit:** hooks aren't copied on clone, so run `uv run pre-commit install` once per clone.

### 7. Noreply email
- **Decision:** keep the personal email out of commits and published content.
- **Did:** got the noreply address with `gh`, set it globally and for this repo, and
  rewrote the existing commits. File contents were confirmed unchanged by tree hash.

### 8. Public release audit
- **Did:** extended `.gitignore`, added `README.md` and an MIT `LICENSE`.
- **Scanned:** every commit, for private keys, tokens, password assignments, Gmail
  addresses and credential-looking filenames, plus `detect-secrets` on each commit.
- **Result:** clean.
- **Problem:** the first scan was invalid. zsh passed the commit IDs as one value and
  errors were hidden, so its zeros meant nothing.
- **Fix:** re-ran under bash with commit validation, visible errors and known-positive
  checks. Lesson: a scan needs a control proving it can find something.

### 9. Public GitHub repo
- **Decision:** public rather than private.
- **Did:** created the repo with `gh`, pushed `main`, and enabled secret scanning and
  push protection.
- **Verified:** read the settings back from the GitHub API: both `enabled`, 0 alerts.
  Push protection has not been tested with a real blocked push.
- **Decision:** `CLAUDE.md` stays in the public repo.

### 10. Reusable audit script
- **Did:** added `scripts/audit_history.sh`. The email to search for is an argument, so
  it is never stored in the public repo. Exit codes: 0 clean, 1 findings, 2 audit failed.
- **Problems fixed before pushing:** `grep -c` returning an error on zero matches, and
  two labels that made the script flag itself.
- **Decision:** no pre-push hook; run the audit in GitHub Actions later.

### 11. Project diary and session routine
- **Did:** created `docs/diary.md` to carry context between sessions, with a
  "Pick up here" section at the top.
- **Did:** added a session routine to `CLAUDE.md`, because `CLAUDE.md` is loaded
  automatically and the diary is not.
- **Decision:** keep the diary public, as a record of how the project was built.

### 12. `/diary` skill
- **Did:** added `.claude/skills/diary/SKILL.md`, which updates this diary in a
  consistent format. It lives in the project, so it is versioned with the repo.
- **Decision:** the skill edits only the diary and doesn't commit or push.
- **Problem:** Claude Code returned `Unknown skill: diary` in the session that created it.
- **Fix:** followed the steps in `SKILL.md` by hand to produce this update.
- **Verified:** the written instructions work. Launching `/diary` as a command was
  not verified at this point (see step 13).

### 13. `/diary` tested as a command
- **Did:** ran `/diary` by typing it, which produced this entry and added `793a4ed`
  to the commits table.
- **Verified:** the command launches and its steps run from `SKILL.md`. It worked in
  the same session that created it, once typed by the user.
- **Not verified:** why the earlier `Unknown skill` error happened. The likely cause
  was that the new skill had not been picked up yet.

### Commits

| Commit | Message |
|---|---|
| `b5f9b11` | Set up project with uv, dbt v2 and raw table script |
| `2ec7e42` | Add pre-commit hook to block private keys |
| `71365ce` | Prepare project for public release |
| `92b4a61` | Add script to audit git history for secrets |
| `793a4ed` | Add project diary, session routine and /diary skill |
| `a6c48ed` | Log /diary command test in the project diary |

---

## 2026-11-09: BigQuery authentication with gcloud

### 1. Table expiration checked
- **Did:** read "Table expiration" on `raw.iowa_sales` in the BigQuery console. The
  table has an expiration set, so the open question from the first session is answered.
- **Problem:** creating a Google Calendar reminder was blocked by Claude Code's
  permission check.
- **Decision:** keep the reminder in Claude Code's project memory only. It appears
  only if a session is opened in time, and no calendar event was created.

### 2. Google Cloud CLI installed
- **Did:** installed the `gcloud-cli` Homebrew cask, which provides `gcloud` and `bq`.
- **Why:** needed for BigQuery authentication, and it lets scripts run with `bq`.
- **Verified:** `gcloud --version` and `bq --version` ran. No PATH change was needed.
- **Not done:** the install is not yet in a script. Shell completion was not set up.

### 3. BigQuery authentication
- **Did:** ran `gcloud auth login`, set the default project to `iowa-liquor-lab`, and
  ran `gcloud auth application-default login`.
- **Decision:** gcloud OAuth instead of service account keys.
- **Why two logins:** the first is for `gcloud` and `bq`; ADC is what other programs
  on the Mac are expected to use, such as dbt.
- **Problem:** `gcloud config` was first run without its arguments and errored.
- **Fix:** ran the full `gcloud config set project iowa-liquor-lab`. Nothing had changed.
- **Verified:** the ADC file exists with `600` permissions and is outside the repo, ADC
  obtained an access token, and `iowa-liquor-lab` was added as its quota project.
- **Not verified:** a real BigQuery query. `dbt debug` will be the first test.

### 4. Table expiration check script
- **Did:** added `scripts/check_raw_table.sh`, which reads a table's metadata with `bq`
  and prints when it expires. Exit codes: 0 ok, 1 expires soon, 2 check failed.
- **Why:** to check the expiration from code instead of the BigQuery console.
- **Changed:** `scripts/check_raw_table.sh`.
- **Verified:** the date matched the console. A 100-day window produced the warning, and
  a missing table and an invalid argument both exited 2.
- **Not verified:** this used the `gcloud` login, not ADC, so it doesn't test dbt's access.
