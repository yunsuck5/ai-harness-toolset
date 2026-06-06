# docs/ — Operating Model & Closeout Reconciliation Contract

This is the **repo-contained, CLI-operable** authority for *how a docs change flows through the `docs/` tree* and *what makes a feature/system closeout "done" in the docs*. Any local CLI operator — Claude Code, Codex, or another agent — can read this file plus the docs it points to and decide how a change should propagate top-down, without relying on any external (web) handoff.

It is a **task-scoped execution policy** (read it when your task changes docs or closes out work), not always-on priming and not an artifact contract. It complements, and does not duplicate, the two existing top-level authorities:

- `docs/README.md` — **placement / structure** authority (which folder a doc belongs in, by access pattern). This file does not re-decide placement.
- `docs/current/SOURCE_OF_TRUTH.md` — **per-question authority routing** (which document answers which question). This file does not re-route questions.
- **This file** — the **change/closeout flow** authority (how an edit moves down the tree; the shape contract for STATUS/BACKLOG; the on-demand status-briefing model that replaces committed project-current mirror files; the closeout reconciliation gate).

When this file disagrees with `docs/README.md` on *placement*, `docs/README.md` wins. When it disagrees with a `docs/contracts/**` contract on an *artifact's shape*, that contract wins. This file is authoritative only for the docs change/closeout *process*.

---

## 1. Top-down operating model

Docs authority flows **top-down**. A docs change is decided from the top-level structure downward, never bottom-up from whichever file the work happened to touch:

1. **Structure first.** Before adding or moving content, confirm the placement against `docs/README.md` §5–§6 (access-pattern layers). New always-on rules do not go in `docs/`; they go in `snippets/**` / the managed block, or the repo-local root `CLAUDE.md` / `AGENTS.md` for repo-only rules.
2. **Authority next.** Confirm which layer *owns* the fact you are changing (the "single home" — see §3). Every fact has exactly one authoritative home; all other mentions are pointers to it, never copies.
3. **Down into current + per-system.** Propagate the change into the layers whose role (§3) is affected — `docs/current/` for question→authority routing (`SOURCE_OF_TRUTH.md`), and the relevant `docs/systems/<system>/` files for subsystem state. Project-current *state* is no longer mirrored in a committed file; it is answered on demand (§6).
4. **Closeout gate last.** When the change closes out work, run the two-level closeout reconciliation (§7) before declaring the docs closeout complete.

The governing principle is **single-home-plus-pointers**: duplication is the engine of staleness, because a duplicated fact requires an N-place sweep on every change and any missed place silently goes stale. Prefer one authoritative statement plus pointers over repeated prose.

---

## 2. Reference shape (what "good" looks like)

`docs/systems/review/STATUS.md` and `docs/systems/brief/STATUS.md` are the **reference shape** for a per-system status doc: a few compact current-state bullets, a compact completed-ledger table, accepted-residual-risks, and pointers outward — with narrative externalized. New or revised STATUS docs conform to that shape (§4), not to a longer journal form.

---

## 3. Role of each layer in the change/closeout flow

Placement scope for each folder is defined in `docs/README.md` §5; the table below defines each layer's **operating role** — what it is *for* in the change/closeout flow, and what it must *not* absorb.

| Layer | Operating role in the flow | Must not become |
|---|---|---|
| `docs/current/` | **`SOURCE_OF_TRUTH.md` only — question→authority routing.** It routes each question to its authoritative home. Project-current *state* and the "what's next" action are NOT mirrored here (the former committed mirror files are removed) — they are answered on demand (§6) and persisted for transitions in the canonical Brief. | A second status ledger, a roadmap, a closeout diary, an incident log, or a committed active-action / project-state mirror. |
| `docs/systems/*/STATUS.md` | **Current operational posture of one subsystem + compact completed ledger + accepted residual risks + pointers.** The authoritative "what is true inside this subsystem now." | An incident-narrative store, a dogfood-transcript store, a phase-by-phase build diary, a full closeout report, an implementation plan, or a design contract (those are pointed to, not inlined). |
| `docs/systems/*/BACKLOG.md` | **Open-work entrypoint:** triage-level rows for not-yet-started work (ID + candidate + direction note). | A second status/archive surface (see the tombstone rule, §5). |
| `docs/systems/*/DEFERRED.md` | **Consciously-postponed work, each with a reopen condition.** An item without a reopen condition is not deferred (it is backlog, archive, or delete-candidate). | A duplicate of BACKLOG (deferred ≠ not-yet-started) or a closed-item store. |
| `docs/roadmap/` | **Milestone routing only** (`INDEX.md`, `CURRENT_MILESTONES.md`): the numbered remaining-order *view*, routing to its authority. | A holder of decision/design/planning bodies, or a redefinition of the order (authority = `docs/decisions/POST_MVP_PLAN.md` §11). |
| `docs/backlog/` | **Backlog routing/classification index only** (`INDEX.md`): where open candidates are classified to per-system BACKLOG. | A holder of item bodies. |
| `docs/decisions/` | **Active decision records** (what was decided and why, still carrying authority). | A current-status surface (status → `docs/systems/**`). |

---

## 4. Per-system `STATUS.md` shape / altitude contract

A `STATUS.md` answers exactly one question: **"What is this subsystem's current operational posture, and where are the authoritative details?"** It is written at decision altitude (what the subsystem *is*), not build-diary altitude (how it got there).

**Belongs in STATUS.md:**
- Current state / posture — compact bullets.
- Authoritative contract / model pointers.
- A **compact completed-ledger table** — columns: ID / item / closed-at / current meaning / detail-pointer. One row per closed item; the row is a summary, the detail lives behind the pointer.
- Accepted residual risks carried into maintenance, each with a reopen pointer.
- Explicit non-claims where a closeout could be over-read.
- Maintenance posture.
- Pointers to BACKLOG / DEFERRED / design.

**Does NOT belong in STATUS.md (point to it instead):**
- Open backlog item bodies (→ BACKLOG.md).
- Deferred item bodies already in DEFERRED.md.
- Long incident / root-cause narratives (not maintained as current docs — git history is the preservation mechanism).
- Full closeout reports, dogfood / retest transcripts (not maintained as current docs — git history is the preservation mechanism).
- Implementation plans, design contracts (→ their authority doc).
- Multi-paragraph reconciliation essays (record the supersession as a one-line ledger/pointer change, not an essay).

**No durable sink for externalized detail — git history is the preservation mechanism.** Current docs stay compact and source-managed; historical detail (long narratives, closeout reports, transcripts) is **not** maintained as current docs. If a past decision is still operationally relevant, the active doc states the decision **directly** — derived from current implemented behavior and current git-tracked source-managed docs — rather than pointing at externalized narrative. A committed doc must never use a durable pointer to a gitignored / local / scratch / runtime path (`log/**`, `polishing/**`, `repo_snapshot/**`, repo-sibling artifacts, runtime evidence, user/global files); durable pointers resolve only to git-tracked files or git commit/history.

**Altitude ceiling:** if a current-state bullet has grown into multiple paragraphs of history, that is a signal the narrative must move behind a pointer and the bullet must shrink to current posture. This contract defines the target shape for **new and revised** STATUS content; it does **not** by itself authorize a retroactive rewrite of any existing STATUS doc — that is a separate scoped batch.

---

## 5. `BACKLOG.md` closed-row tombstone behavior

`BACKLOG.md` is the open-work entrypoint. When a backlog row closes:

- The row's **authoritative closed record moves to the subsystem `STATUS.md` completed ledger** (compact row); any long narrative is not migrated into current docs — git history preserves it.
- In `BACKLOG.md` the row is **reduced to a one-line tombstone** for ID continuity: `**[CLOSED]** <ID> — <one-line outcome>; see STATUS ledger <ID>.` A tombstone carries no closeout/incident narrative.
- A `**[RETIRED]**` row (closed by a not-doing decision) follows the same one-line tombstone form with a pointer to where the retirement rationale lives.

The tombstone exists so a reader scanning BACKLOG sees only open work plus short markers that an ID was used and closed — never full closed bodies that turn BACKLOG into a second status/archive surface.

**This batch defines the tombstone rule; it does not retroactively tombstone existing closed rows.** Converting already-closed long rows (e.g. existing IU-B-* closed rows) to tombstones is a separate scoped batch under this contract.

---

## 6. Project-current state — the on-demand status-briefing model

There is **no committed project-current mirror file** — there is no committed active queue and no committed project-current summary. "What is done / what remains / what should I do next" is answered **on demand** by the agent, not maintained as a committed summary that goes stale between closeouts.

**Removed surfaces:**
- The former `docs/current/NEXT_ACTIONS.md` (committed active queue) and `docs/current/PROJECT_STATE.md` (committed project-current summary) **have been removed from the repo** — they are deleted, not kept as stubs or path-preserving placeholders. The currently selected action lives in the working conversation and, across sessions, in the canonical Brief (`<ProjectRoot>/log/brief/BRIEF.md`) and handoff `next_action`. A committed "active now" / project-state file mirrors a conversational decision and the live system surfaces, and goes stale the moment they move on, so it is not maintained and not recreated.
- `docs/current/` now holds **`SOURCE_OF_TRUTH.md` only** — question→authority routing. It is not a project-current state or next-action surface.

**The on-demand status-briefing model.** When a user asks "what's done / what remains / what should I do next," the agent:
1. **Reads the authoritative surfaces** — per-system `docs/systems/*/STATUS.md` completed-ledgers + current-state/LTS sections (done), `docs/systems/*/BACKLOG.md` (open, via `docs/backlog/INDEX.md`), `docs/systems/*/DEFERRED.md` (postponed + reopen conditions), and `docs/roadmap/CURRENT_MILESTONES.md` ↔ `docs/decisions/POST_MVP_PLAN.md` §11 (numbered remaining order); plus the canonical Brief as **runtime restore evidence** when present.
2. **Synthesizes a conversational briefing** at the altitude asked for (whole-project or one subsystem).
3. **The user selects the next task conversationally.** No project-current mirror is written; the selection persists in the conversation and, for transitions, in the Brief (+ handoff `next_action`).

The single home of "what remains" is therefore the per-system STATUS/BACKLOG/DEFERRED + roadmap/decisions surfaces; the single home of "the currently selected action" is the conversation + Brief. Neither is a committed `docs/current/` summary.

---

## 7. Closeout reconciliation — two-level gate

A feature/system closeout is **not "done" in the docs** until **both** levels below pass. Both are mandatory; the listing order is the verification order (orient from the top first), not a priority ranking — the system-local edits are usually written first, then verified upward.

### Level 1 — project-current / upward impact check (top-down)
Check, and reconcile if affected, the top-level orientation surfaces a new reader hits first. Because project-current state is answered on demand (§6) rather than mirrored, this level is small — the committed project-current mirror files have been removed, so there is no project-current summary or active-queue file to re-sync. Check only these, and only when their authority / routing / order actually changes:
- `docs/current/SOURCE_OF_TRUTH.md` — did any question's authoritative home change (including how "current progress / next action" routes)?
- `docs/roadmap/CURRENT_MILESTONES.md` — did a numbered-milestone status change?
- `docs/decisions/POST_MVP_PLAN.md` — only if the numbered-order authority itself changed.

### Level 2 — system-local impact check
Check, and reconcile if affected, the subsystem's own surfaces:
- `docs/systems/<system>/STATUS.md` — completed-ledger row added; current-state posture updated; accepted-residual-risk / non-claim updated; intra-system supersessions recorded as one-line ledger/pointer changes (§4).
- `docs/systems/<system>/BACKLOG.md` — closed row tombstoned (§5).
- `docs/systems/<system>/DEFERRED.md` — updated only if a reopen condition changed or an item resolved.
- Any subsystem design/contract pointer that the closeout invalidated.

**Why both.** Level 2 keeps the subsystem internally truthful (no open-looking closed items, deferred items keep their reopen boundaries). Level 1 keeps the project's first orientation surfaces honest for a new reader. They answer different questions — "what is true inside this subsystem?" vs "what should a new reader believe about the project now?" — so neither substitutes for the other. The failure mode this gate exists to prevent is a subsystem that is locally correct while `docs/current/` still points operators at a stale priority.

### Required "checked: no change required" reporting rule
Both levels are **inspect-all, report-each**. For every doc listed in Level 1 and Level 2, the closeout report must state one of:
- `updated: <file> — <what changed>`, or
- `checked: no change required — <file>`.

Silently skipping a listed doc is a gate failure: a doc that was never mentioned is indistinguishable from a doc that was forgotten, which is exactly how `docs/current/` goes stale. The positive "checked: no change required" line is what makes the two-level gate auditable by the next operator (and by the Codex reviewer).

---

## 8. What this document does NOT do

- It defines the docs change/closeout *process*; applying that process to any specific surface is its own scoped batch. The project-current mirror removal (the former `NEXT_ACTIONS.md` and `PROJECT_STATE.md` deleted, §6) has been performed; still-deferred applications under this contract are **retroactive STATUS narrative trimming** and **retroactive BACKLOG closed-row tombstoning** (§4, §5) — each a separate scoped batch, not done merely because this contract names the rule.
- It does **not** restructure folders, move/archive existing narrative, or collapse the roadmap/backlog routing layers — those are out of this contract's scope and need their own scoped decisions governed by `docs/README.md`.
- It does **not** approve any commit / push / publish / merge / release, or any global/user filesystem mutation. It governs repo docs process only.
- A Codex review verdict (`yes` / `no` / `yes with risk`) on a docs change does not auto-approve commit/push; that remains an explicit user decision.

---

## 9. Codex review gate & source-of-truth relationship

Any source/doc change governed by this model goes through the normal Codex review gate (`scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1 -RequireResult`, or the equivalent `ai-harness-review` skill). A verdict does not auto-approve commit/push/publish/merge/release/adoption.

- Docs **placement/structure** authority: `docs/README.md`.
- Docs **per-question authority routing**: `docs/current/SOURCE_OF_TRUTH.md`.
- Docs **change/closeout flow + STATUS/BACKLOG shape + the on-demand status-briefing model**: this file.

These three are complementary single-home authorities; on overlap, placement defers to `docs/README.md`, question-routing to `SOURCE_OF_TRUTH.md`, and process to this file.
