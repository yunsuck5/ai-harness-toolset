# docs/ — Hierarchy and Access-Pattern Policy

This file is the **placement and navigation authority** for `docs/`. It defines where a document belongs and how AI/operator and humans should read the tree. It does not route questions to authoritative documents — that is `docs/current/SOURCE_OF_TRUTH.md` (see §10).

## 1. Purpose

The folder structure under `docs/` is an **AI/operator scope-control surface**, not cosmetic tidiness. An agent expands context by folder listing, neighboring files, same-directory search, and reference chains. The goal of this structure is **drift control**: when a folder or file is opened for one task, unrelated scope should not be pulled in; and rules that are always read together should not be scattered.

## 2. Absolute rule: docs root markdown

`docs/` root contains **only `README.md`**. No other markdown file lives at `docs/` root. (This applies to the `docs/` folder only — not to the repo-root `README.md` or `INSTALL.md`.)

## 3. A folder is a scope boundary, not a storage bucket

Markdown in the same folder must be interpretable, when read together, under **one purpose and one authority**. New folders are created only to narrow scope. Subfolders are not created to mix unrelated scope, and not created merely because the taxonomy looks complete.

## 4. Structure follows access pattern

The primary placement criterion is **how a document is read**, not how many topics it touches.

- **Always-on / priming** — rules read regardless of task → **consolidate**. Splitting them creates cross-reference chains, and that coupling causes drift. The bar to be "always-on" is high: it must apply to *every* task, with no conditional content. In this repo the genuine always-on payload lives in `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` (the adopted `CLAUDE.md` / `AGENTS.md` managed block) and global instructions — **not** under `docs/`. There is therefore no `docs/priming/` folder.
- **Task-scoped / lookup** — read selectively per task → **partition**, so opening one task's folder does not drag in unrelated scope.
- **anti-mixing** — unrelated scopes must not share a lookup context.
- **anti-fragmentation** — always-read or tightly-coupled material must not be scattered into a dense reference web. Splitting succeeds only if each piece has one access pattern, one purpose, is readable standalone, and does not require a dense reference chain.

## 5. Folder layers

| Folder | Scope (one purpose) | Access pattern |
|---|---|---|
| `docs/current/` | `SOURCE_OF_TRUTH.md` only — question→authority routing; project-current state / next action answered on demand (`docs/policies/DOCS_OPERATING_MODEL.md` §6), not mirrored in any committed file | read first / when orienting |
| `docs/policies/` | task-scoped AI/operator execution policies (PowerShell, CLI/runtime assumptions, reviewer config, review effort) | when a task touches that policy's domain |
| `docs/contracts/` | artifact/protocol contracts (`review/`, `brief/`, `chatlog/`, `evidence/`, `global-invocation/`) | when producing/validating that artifact |
| `docs/systems/` | per-subsystem STATUS / BACKLOG / DEFERRED + the install/update operating model; routes to contracts/policies, does not replace them | when checking a subsystem's state |
| `docs/architecture/` | cross-cutting architecture decisions/audits spanning multiple subsystems/surfaces, deciding a structural target **before** implementation (e.g. `architecture/instruction-surface/INSTRUCTION_SURFACE_PLAN.md`); routes to `docs/systems/**` for current state, does not own it | when planning/auditing how a concern is divided across surfaces |
| `docs/project/` | project identity, scope, positioning, philosophy | when scoping "what this project is/isn't" |
| `docs/decisions/` | active decision records (incl. post-MVP decision record + numbered-order authority) | when checking "what was decided" |
| `docs/user_guide/` | human-facing operation / evaluation / adoption guides | when a human learns or evaluates the tool |
| `docs/roadmap/` | roadmap/milestone routing only (INDEX, current milestones) | when checking remaining order |
| `docs/backlog/` | backlog index/routing only | when looking up open work |

**`docs/architecture/` vs `docs/systems/`.** `docs/systems/<system>/` describes *one implemented subsystem's current operational posture* (per-subsystem, existing state). `docs/architecture/<concern>/` decides *the target structure for a concern that spans several subsystems/surfaces, before implementation* (cross-cutting, design-stage); it owns no subsystem's current state and points at `docs/systems/**` for it. It also differs from `docs/decisions/` (settled decision records) by being multi-surface planning/audit with classification criteria and option analysis. The layer's own scope/contrast lives in `docs/architecture/README.md`.

## 6. Where new documents belong

Ask, in order: (1) Is this *always-on for every task*? If yes, it belongs in the snippet/global payload, not `docs/`. (2) Otherwise, which single access pattern / scope does it serve? Place it in that layer. (3) Would co-locating it pull unrelated scope into a task search? If yes, partition. (4) Would splitting it create a dense reference chain? If yes, keep it consolidated. Never create an empty folder in advance.

## 7. How AI/operator should navigate docs

Start from `docs/current/SOURCE_OF_TRUTH.md` for "which document is authoritative for this question." Open only the scope folder your task needs. Do not treat a `user_guide/` document as a policy/contract authority.

## 8. How humans should navigate docs

Start from `docs/user_guide/` for operating and evaluating the tool, and `README.md` (repo root) for the high-level overview. For "what is done / what remains / what to do next," ask the agent for an on-demand status briefing (`docs/policies/DOCS_OPERATING_MODEL.md` §6) or read per-system `docs/systems/*/STATUS.md` directly; there is no committed project-current summary file.

## 9. What not to do

Do not place AI/operator execution policy under `user_guide/`. Do not place artifact contracts under `policies/`. Do not put task-scoped or conditional policy into always-on priming. Do not leave any markdown at `docs/` root except this file. Do not preserve a location merely because it was recently committed or heavily referenced.

## 10. Relationship to `docs/current/SOURCE_OF_TRUTH.md` and the operating model

- `docs/README.md` (this file): the docs **structure/placement** policy (which folder a doc belongs in).
- `docs/current/SOURCE_OF_TRUTH.md`: per-question **authority routing** (which document answers which question, and the priority order on conflict).
- `docs/policies/DOCS_OPERATING_MODEL.md`: the docs **change/closeout flow** — how an edit propagates top-down into `docs/current/` and per-system docs, the per-system `STATUS.md` shape/altitude contract, the `BACKLOG.md` closed-row tombstone rule, the on-demand status-briefing model (the committed project-current mirror files `NEXT_ACTIONS.md` / `PROJECT_STATE.md` were removed), and the two-level closeout reconciliation gate. Read it when changing docs or closing out work.

These three are complementary single-home authorities: on overlap, placement defers to this file, question-routing to `SOURCE_OF_TRUTH.md`, and change/closeout process to `DOCS_OPERATING_MODEL.md`.

## 11. Reference update rule when moving docs

Moving or splitting a document requires updating every inbound reference (in `docs/**`, `README.md`, and — path-only/comment-only — protected files when they reference the moved path). A document's section anchors referenced elsewhere must be preserved or explicitly remapped.

## 12. Historical preservation

Superseded / historical material is preserved in **git history**, not maintained as current docs (there is no separate archive docs tree). Current docs stay compact and self-contained; when a past decision is still operationally relevant, the active doc states it directly rather than pointing at retained narrative.
