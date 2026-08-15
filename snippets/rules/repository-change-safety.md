# Rule: Repository change safety

## Commit / push need explicit approval

- Commit, push, publish, merge, release, deploy, and upload each require **explicit user approval** per change set. A review verdict (`yes` / `no` / `yes with risk`) approves none of them — it is informational, and the next action is always a separate explicit user decision. `yes with risk` is not the automatic equivalent of `yes`.
- A review stage or artifact boundary does not by itself require a separate commit. Commit boundaries follow independently verifiable, revertible, dependency-atomic change sets; every resulting change set still requires its own explicit user approval.
- Determine commit readiness from the authorized source and Git facts that bear on the proposed change set. Do not require or create per-file hashes, preimages, byte/content bindings, or a separate persistent proof bundle to re-prove that a completed review still applies at commit time.
- Before any state-changing git action, confirm the repository root, branch, and status.
- Before commit, inspect the actual staged target for conflicts and missing, unintended, or otherwise incorrect staging.
- **Staging changes the index.** Any check that reads the index or the tracked-file set must be **re-run after staging and before commit** — a prior pass on the unstaged tree does not carry over.
- This completed-review boundary does not waive a hash, content-binding, or integrity contract that has a separate concrete consumer and protects an identified failure outside review re-proving.

## Instruction vs machine-enforced invariant

- When an instruction conflicts with a machine-enforced repository invariant (an enforcement script, a contract, a tracked-path rule), **stop and surface the conflict before executing** — never silently bypass with force flags such as `add -f`.
- Force-adding an ignored runtime artifact is such an exception: it requires **explicit confirmation of the exception itself**, not just approval of the surrounding task.

## No automatic `.gitignore` mutation

- Never automatically mutate the target project's `.gitignore`. Treating the runtime `log/` tree — including the canonical Brief at `<ProjectRoot>/log/brief/BRIEF.md` — as untracked is the standing assumption, but adding the ignore entry is a user decision, not an automatic edit.

## Temporary-file hygiene

- Temporary files created **solely** for command execution are cleaned up by the operator before closeout; on the success path this normal cleanup is automatic and needs no separate prompt or approval. A **distinct** boundary governs any leftover that *remains* after that cleanup (a delete that failed, or an artifact deliberately held for investigation): report its path and delete it only after separate explicit user approval.
- Evidence, snapshots, logs, source changes, and user-requested artifacts are **not** temporary files and are never swept by this rule.
