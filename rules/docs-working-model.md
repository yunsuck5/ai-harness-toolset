# Rule: Documentation working model (repo-only)

Applies to developing the `ai-harness-toolset` repository — the binding rules for *how a docs change flows through the `docs/` tree* and *what makes a feature/system closeout "done" in the docs*. **Rationale / derivation:** `docs/policies/DOCS_OPERATING_MODEL.md` (the why + the record + the role-of-layers orientation) — the rules below are the binding active-surface form (per the root *Final hard rule*), not a restatement of that record. Placement (`docs/README.md`) and per-question routing (`docs/current/SOURCE_OF_TRUTH.md`) are separate docs surfaces this rule does not redefine.

Read this rule **before** changing `docs/` content or closing out work; the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* (`Source / docs` row) wires that trigger. The file existing is not what makes it apply — it applies because the root instruction files trigger it.

## When this rule applies

- Any task that **changes `docs/` content** or **closes out work in the docs**.
- It governs the docs change/closeout **process only**. It does not re-decide placement (→ `docs/README.md`) or question-routing (→ `docs/current/SOURCE_OF_TRUTH.md`).

## Top-down operating model

A docs change is decided from the top-level structure downward, never bottom-up from whichever file the work happened to touch:

1. **Structure first.** Before adding or moving content, confirm placement against `docs/README.md` §5–§6 (access-pattern layers). New always-on rules do not go in `docs/`; they go in `snippets/**` / the managed block, or — for repo-only rules — the repo-local root `CLAUDE.md` / `AGENTS.md` and the `rules/**` they point to.
2. **Authority next.** Confirm which layer *owns* the fact you are changing (its single home — see *single-home-plus-pointers*).
3. **Down into current + per-system.** Propagate the change into the layers whose role is affected — `docs/current/` for question→authority routing, and the relevant `docs/systems/<system>/` files for subsystem state. Project-current *state* is answered on demand (see *On-demand status-briefing model*), not mirrored in a committed file.
4. **Closeout gate last.** When the change closes out work, run the two-level closeout reconciliation (below) before declaring the docs closeout complete.

**single-home-plus-pointers.** Every fact has exactly one authoritative home; all other mentions are pointers to it, never copies. Prefer one authoritative statement plus pointers over repeated prose. (Why duplication is the staleness engine: `docs/policies/DOCS_OPERATING_MODEL.md` §1.)

## Doc-vs-doc precedence

- On a **placement** disagreement, `docs/README.md` wins.
- On an **artifact's shape**, the relevant `docs/contracts/**` contract is the specification of record and the operative authority is the **active surface** (the verifier scripts / templates / skill the contract records) — neither doc outranks the active surface.
- On the docs **change/closeout process**, this rule is the home.

## Layer shape constraints (must-not-absorb)

A closeout must not let a layer absorb what it must not become:

- `docs/current/` — `SOURCE_OF_TRUTH.md` only (question→authority routing). Must not become a second status ledger, a roadmap, a closeout diary, an incident log, or a committed active-action / project-state mirror.
- `docs/systems/*/STATUS.md` — must not become an incident-narrative / dogfood-transcript / build-diary store, a full closeout report, an implementation plan, or a design contract (those are pointed to, not inlined).
- `docs/systems/*/BACKLOG.md` — must not become a second status/archive surface (see the tombstone rule).
- `docs/systems/*/DEFERRED.md` — an item without a reopen condition is not deferred (it is backlog, archive, or delete-candidate). Must not duplicate BACKLOG or store closed items.
- `docs/roadmap/` — must not hold decision/design/planning bodies or redefine the order (order authority = `docs/decisions/POST_MVP_PLAN.md` §11).
- `docs/backlog/` — must not hold item bodies (routing/classification index only).
- `docs/decisions/` — must not become a current-status surface (status → `docs/systems/**`).

## Per-system STATUS.md shape / altitude

A `STATUS.md` answers exactly one question: the subsystem's current operational posture and where the authoritative details are. It is written at decision altitude (what the subsystem *is*), not build-diary altitude (how it got there). Reference shape: `docs/systems/review/STATUS.md` and `docs/systems/brief/STATUS.md`. New or revised STATUS content conforms to that shape, not a longer journal form.

**Belongs in STATUS.md:**
- Current state / posture — compact bullets.
- Authoritative contract / model pointers.
- A compact completed-ledger table — columns: ID / item / closed-at / current meaning / detail-pointer; one row per closed item (the row is a summary, the detail lives behind the pointer).
- Accepted residual risks carried into maintenance, each with a reopen pointer.
- Explicit non-claims where a closeout could be over-read.
- Maintenance posture.
- Pointers to BACKLOG / DEFERRED / design.

**Does NOT belong in STATUS.md (point to it instead):**
- Open backlog item bodies (→ BACKLOG.md).
- Deferred item bodies already in DEFERRED.md.
- Long incident / root-cause narratives, full closeout reports, dogfood / retest transcripts (not maintained as current docs — git history is the preservation mechanism).
- Implementation plans, design contracts (→ their authority doc).
- Multi-paragraph reconciliation essays (record the supersession as a one-line ledger/pointer change, not an essay).

**Durable-pointer prohibition.** A committed doc must never use a durable pointer to a gitignored / local / scratch / runtime path (`log/**`, `polishing/**`, `repo_snapshot/**`, repo-sibling artifacts, runtime evidence, user/global files); durable pointers resolve only to git-tracked files or git commit/history. Externalized historical detail is preserved by git history, not by a durable sink — if a past decision is still operationally relevant, the active doc states the decision directly (derived from current implemented behavior and current git-tracked docs).

**Altitude ceiling.** If a current-state bullet has grown into multiple paragraphs of history, the narrative moves behind a pointer and the bullet shrinks to current posture. This shape governs **new and revised** STATUS content; it does not by itself authorize a retroactive rewrite of any existing STATUS doc (that is a separate scoped batch).

## BACKLOG.md closed-row tombstone

When a backlog row closes:
- The authoritative closed record moves to the subsystem `STATUS.md` completed ledger (compact row); any long narrative is not migrated into current docs — git history preserves it.
- In `BACKLOG.md` the row is reduced to a one-line tombstone for ID continuity: `**[CLOSED]** <ID> — <one-line outcome>; see STATUS ledger <ID>.`
- A `**[RETIRED]**` row (closed by a not-doing decision) uses the same one-line tombstone form with a pointer to where the retirement rationale lives.
- A tombstone carries no closeout/incident narrative.

This rule does not retroactively tombstone existing closed rows (that is a separate scoped batch).

## On-demand status-briefing model

There is **no committed project-current mirror file** — no committed active queue and no committed project-current summary. "What is done / what remains / what should I do next" is answered **on demand** by the agent, not maintained as a committed summary that goes stale between closeouts.

When asked, the agent:
1. **Reads the authoritative surfaces** — per-system `docs/systems/*/STATUS.md` completed-ledgers + current-state/LTS sections (done), `docs/systems/*/BACKLOG.md` (open, via `docs/backlog/INDEX.md`), `docs/systems/*/DEFERRED.md` (postponed + reopen conditions), and `docs/roadmap/CURRENT_MILESTONES.md` ↔ `docs/decisions/POST_MVP_PLAN.md` §11 (numbered remaining order); plus the canonical Brief as runtime restore evidence when present.
2. **Synthesizes a conversational briefing** at the altitude asked for (whole-project or one subsystem).
3. **The user selects the next task conversationally.** No project-current mirror is written.

The single home of "what remains" is the per-system STATUS/BACKLOG/DEFERRED + roadmap/decisions surfaces; the single home of "the currently selected action" is the conversation + the canonical Brief.

## Closeout reconciliation — two-level gate

A feature/system closeout is **not "done" in the docs** until **both** levels below pass. Both are mandatory; the listing order is the verification order (orient from the top first), not a priority ranking — the system-local edits are usually written first, then verified upward.

**Level 1 — project-current / upward impact check (top-down).** Check, and reconcile if affected, the top-level orientation surfaces a new reader hits first — only when their authority / routing / order actually changes:
- `docs/current/SOURCE_OF_TRUTH.md` — did any question's authoritative home change (including how "current progress / next action" routes)?
- `docs/roadmap/CURRENT_MILESTONES.md` — did a numbered-milestone status change?
- `docs/decisions/POST_MVP_PLAN.md` — only if the numbered-order authority itself changed.

**Level 2 — system-local impact check.** Check, and reconcile if affected, the subsystem's own surfaces:
- `docs/systems/<system>/STATUS.md` — completed-ledger row added; current-state posture updated; accepted-residual-risk / non-claim updated; intra-system supersessions recorded as one-line ledger/pointer changes.
- `docs/systems/<system>/BACKLOG.md` — closed row tombstoned.
- `docs/systems/<system>/DEFERRED.md` — updated only if a reopen condition changed or an item resolved.
- Any subsystem design/contract pointer that the closeout invalidated.

**Inspect-all, report-each.** For every doc listed in Level 1 and Level 2, the closeout report must state one of:
- `updated: <file> — <what changed>`, or
- `checked: no change required — <file>`.

Silently skipping a listed doc is a gate failure — a doc that was never mentioned is indistinguishable from a doc that was forgotten. (Why both levels exist: `docs/policies/DOCS_OPERATING_MODEL.md` §7.)

## Scope of an application + review gate

- This rule defines the docs change/closeout **process**; applying it to any specific surface is its own scoped batch. It does not restructure folders, move/archive existing narrative, or collapse routing layers — those need their own scoped decisions governed by `docs/README.md`.
- It does **not** approve any commit / push / publish / merge / release, or any global/user filesystem mutation.
- Any source/doc change governed by this model goes through the normal Codex review gate (`scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1 -RequireResult`, or the equivalent `ai-harness-review` skill). A verdict (`yes` / `no` / `yes with risk`) does not auto-approve commit / push / publish / merge / release / adoption.

## Tier note

This is a repo-development rule for this repo only; it is **not** adopter-universal and **not** part of the global distribution (an adopter project may use a different docs authority model). It is not duplicated into `snippets/rules/`. Its rationale, removal record, and role-of-layers orientation live in `docs/policies/DOCS_OPERATING_MODEL.md`.
