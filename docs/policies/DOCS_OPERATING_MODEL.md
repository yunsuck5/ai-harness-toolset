# docs/ — Operating Model: rationale, record & layer orientation

**Status: non-authority record / rationale / orientation — not the operative rule.** This file no longer carries the binding docs change/closeout rules. The operative rules — top-down flow, single-home-plus-pointers, the per-system `STATUS.md` shape, the `BACKLOG.md` tombstone form, the on-demand status-briefing model, and the two-level closeout reconciliation gate — now live on the **active surface** at **`rules/docs-working-model.md`** (the repo-only rules tier, triggered before a docs change/closeout by the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map*). Per the root *Final hard rule*, a binding rule must not live only in `docs/**`; this file keeps the **why** and the **record**, the rule keeps the **what**.

This file is one of several complementary docs surfaces — `docs/README.md` (placement orientation map) and `docs/current/REPO_READING_GUIDE.md` (question read-first routing) are two others, and the binding placement + change/closeout rules live on the active surface at `rules/docs-working-model.md`. The section numbers below are preserved so existing `§N` references resolve; each section now holds rationale/record/orientation and points to the operative rule.

---

## 1. Why top-down + single-home-plus-pointers (rationale)

The model reasons a docs change from the top-level structure downward rather than bottom-up from whichever file the work happened to touch, so a change is placed and owned deliberately instead of accreting wherever it landed. The governing idea is **single-home-plus-pointers**: duplication is the engine of staleness, because a duplicated fact requires an N-place sweep on every change and any missed place silently goes stale — so one authoritative statement plus pointers beats repeated prose.

→ Operative procedure and the single-home rule: `rules/docs-working-model.md` (*Top-down operating model*, *Doc-vs-doc precedence*).

## 2. Reference shape (orientation)

`docs/systems/review/STATUS.md` and `docs/systems/brief/STATUS.md` are the **reference shape** for a per-system status doc: a few compact current-state bullets, a compact completed-ledger table, accepted-residual-risks, and pointers outward — with narrative externalized.

→ The shape that new/revised STATUS content must conform to: `rules/docs-working-model.md` (*Per-system STATUS.md shape / altitude*).

## 3. Role of each layer (orientation map)

Placement scope for each folder is defined in `docs/README.md` §5; the map below is a reading aid for what each docs layer is *for* in the change/closeout flow. The binding "must-not-absorb" constraints are the operative rule (→ `rules/docs-working-model.md` *Layer shape constraints*).

| Layer | What it is for (orientation) |
|---|---|
| `docs/current/` | `REPO_READING_GUIDE.md` only — question→read-first routing. Project-current *state* is answered on demand (§6), not mirrored here. |
| `docs/systems/*/STATUS.md` | The authoritative "what is true inside this subsystem now" — current posture, compact completed ledger, accepted residual risks, pointers. |
| `docs/systems/*/BACKLOG.md` | Open-work entrypoint: triage-level rows for not-yet-started work. |
| `docs/systems/*/DEFERRED.md` | Consciously-postponed work (carried with reopen conditions). |
| `docs/roadmap/` | Milestone routing — the numbered remaining-order view, routing to its authority. |
| `docs/backlog/` | Backlog routing/classification index. |
| `docs/decisions/` | Active decision records (what was decided and why). |

## 4. Why STATUS/BACKLOG stay compact + the durable-pointer rationale

Current docs stay compact and source-managed; historical detail (long narratives, closeout reports, transcripts) is **not** maintained as current docs, because a duplicated or externalized "current" surface drifts the moment the live state moves on. Git history is the preservation mechanism — so a still-relevant past decision is stated directly in the active doc rather than pointed at via externalized narrative. The durable-pointer constraint that follows from this reasoning (where a committed doc's pointers may resolve) is carried as the operative rule, not restated here.

→ Operative STATUS belongs/does-not-belong, the altitude ceiling, the durable-pointer prohibition, and the BACKLOG tombstone form: `rules/docs-working-model.md` (*Per-system STATUS.md shape / altitude*, *BACKLOG.md closed-row tombstone*).

## 5. Why the BACKLOG tombstone exists (rationale)

The tombstone exists so a reader scanning `BACKLOG.md` sees only open work plus short markers that an ID was used and closed — never full closed bodies that would turn BACKLOG into a second status/archive surface.

→ Operative tombstone form: `rules/docs-working-model.md` (*BACKLOG.md closed-row tombstone*).

## 6. Project-current state — the on-demand model (record + rationale)

**Record.** The former committed project-current mirrors `docs/current/NEXT_ACTIONS.md` (committed active queue) and `docs/current/PROJECT_STATE.md` (committed project-current summary) **have been removed** from the repo — deleted, not kept as stubs or path-preserving placeholders. `docs/current/` now holds `REPO_READING_GUIDE.md` only.

**Rationale.** A committed "active now" / project-state file mirrors a conversational decision and the live system surfaces, and goes stale the moment they move on — so "what is done / what remains / what next" is answered on demand instead, and the currently selected action lives in the conversation and, across sessions, in the canonical Brief (`<ProjectRoot>/log/brief/BRIEF.md`).

→ Operative briefing procedure (which surfaces to read, how to synthesize): `rules/docs-working-model.md` (*On-demand status-briefing model*).

## 7. Why the closeout gate is two-level (rationale)

The gate is two-level because Level 2 keeps a subsystem internally truthful (no open-looking closed items; deferred items keep their reopen boundaries) while Level 1 keeps the project's first orientation surfaces honest for a new reader. They answer different questions — "what is true inside this subsystem?" vs "what should a new reader believe about the project now?" — so neither substitutes for the other. The failure mode the gate exists to prevent is a subsystem that is locally correct while `docs/current/` still points operators at a stale priority.

→ Operative gate (Level 1 / Level 2 checklists + the inspect-all / report-each rule): `rules/docs-working-model.md` (*Closeout reconciliation — two-level gate*).

## 8. Scope of an application (record)

Applying this model to any specific surface is its own scoped batch. The project-current mirror removal (§6) has already been performed; still-deferred applications under this model are **retroactive STATUS narrative trimming** and **retroactive BACKLOG closed-row tombstoning**, each a separate scoped batch — not done merely because the model names the rule. The model does not restructure folders, move/archive existing narrative, or collapse routing layers, and it approves no commit / push.

→ Operative scope + Codex-review-gate rule: `rules/docs-working-model.md` (*Scope of an application + review gate*).

## 9. The complementary docs surfaces (orientation)

- Placement — orientation map `docs/README.md`; binding rule `rules/docs-working-model.md` (*Docs placement*).
- Per-question read-first routing → `docs/current/REPO_READING_GUIDE.md`.
- Docs change/closeout process (operative rule) → `rules/docs-working-model.md`; this file holds its rationale and record.

On overlap, the placement orientation map is `docs/README.md` (its binding rule and the change/closeout process live in `rules/docs-working-model.md`), and read-first routing is `REPO_READING_GUIDE.md`.
