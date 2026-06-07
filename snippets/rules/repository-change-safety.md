# Rule: Repository change safety

## Commit / push need explicit approval

- Commit, push, publish, merge, release, deploy, and upload each require **explicit user approval** per change set. A review verdict (`yes` / `no` / `yes with risk`) approves none of them — it is informational, and the next action is always a separate explicit user decision. `yes with risk` is not the automatic equivalent of `yes`.
- Before any state-changing git action, confirm the repository root, branch, and status.

## No automatic `.gitignore` mutation

- Never automatically mutate the target project's `.gitignore`. Treating the runtime `log/` tree — including the canonical Brief at `<ProjectRoot>/log/brief/BRIEF.md` — as untracked is the standing assumption, but adding the ignore entry is a user decision, not an automatic edit.

## Temporary-file hygiene

- Temporary files created **solely** for command execution are cleaned up by the operator before closeout. If such clutter remains, report its path; delete it only after separate explicit user approval.
- Evidence, snapshots, logs, source changes, and user-requested artifacts are **not** temporary files and are never swept by this rule.
