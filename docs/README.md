# docs/ — Docs Tree Orientation & Placement Map

This file is the **docs tree orientation / placement map** — a reading aid for what each `docs/` layer is *for* and how AI/operator and humans navigate the tree. It is **not** an operative authority. The binding placement rules (docs-root-holds-only-`README.md`, folder-as-scope-boundary, where-a-new-doc-belongs, the reference-update-on-move rule) live on the active surface at **`rules/docs-working-model.md`** (*Docs placement*), per the root *Final hard rule*; this file keeps the **map** and the **why**. Question routing is `docs/current/REPO_READING_GUIDE.md` (§10); the docs change/closeout process rule is `rules/docs-working-model.md`.

The section numbers below are preserved so existing `§N` references resolve; binding-rule sections now hold orientation + a pointer to the operative rule.

## 1. Purpose (rationale)

The folder structure under `docs/` is an **AI/operator scope-control surface**, not cosmetic tidiness. An agent expands context by folder listing, neighboring files, same-directory search, and reference chains. The goal of this structure is **drift control**: when a folder or file is opened for one task, unrelated scope should not be pulled in; and rules that are always read together should not be scattered.

## 2. docs root markdown (orientation)

`docs/` root holds **only `README.md`** — no other markdown lives at `docs/` root (this applies to the `docs/` folder only, not the repo-root `README.md` or `INSTALL.md`).

→ Operative rule: `rules/docs-working-model.md` (*Docs placement*).

## 3. A folder is a scope boundary (orientation)

Markdown in one folder is meant to be interpretable, read together, under one purpose — a folder narrows scope rather than collecting unrelated material.

→ Operative rule (folder-as-scope-boundary constraint): `rules/docs-working-model.md` (*Docs placement*).

## 4. Structure follows access pattern (orientation)

The placement criterion is **how a document is read**, not how many topics it touches.

- **Always-on / priming** — rules read regardless of task consolidate **outside** `docs/`. The bar to be "always-on" is high: it must apply to *every* task, with no conditional content. In this repo the genuine always-on payload lives outside `docs/`: the global adopter-universal invariants in `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` (the managed block adopted into the operator's global `CLAUDE.md` / `AGENTS.md`) plus global instructions, and the repo-development-only **repo-local instruction surface** — the tracked root `CLAUDE.md` / `AGENTS.md` (`docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md`). None of these is under `docs/`; there is therefore no `docs/priming/` folder.
- **Task-scoped / lookup** — read selectively per task, partitioned so opening one task's folder does not drag in unrelated scope.
- **anti-mixing** — unrelated scopes do not share a lookup context.
- **anti-fragmentation** — always-read or tightly-coupled material is not scattered into a dense reference web.

→ Operative rule (the binding consolidate / partition / anti-mixing / anti-fragmentation form): `rules/docs-working-model.md` (*Docs placement*).

## 5. Folder layers (the map)

| Folder | Scope (one purpose) | Access pattern |
|---|---|---|
| `docs/current/` | `REPO_READING_GUIDE.md` only — question→read-first routing; project-current state / next action answered on demand (`docs/policies/DOCS_OPERATING_MODEL.md` §6), not mirrored in any committed file | read first / when orienting |
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

## 6. Where new documents belong (orientation)

Briefly: an always-on-for-every-task rule belongs on an always-on surface outside `docs/`; otherwise a doc goes in the single layer (§5) matching its access pattern, partitioned to avoid pulling unrelated scope and kept consolidated to avoid a dense reference chain.

→ Operative rule (the ordered where-a-new-doc-belongs procedure): `rules/docs-working-model.md` (*Docs placement*).

## 7. How AI/operator should navigate docs

Start from `docs/current/REPO_READING_GUIDE.md` for "which document do I read first for this question" (read-first routing, not authority over the active surface). Open only the scope folder your task needs. Do not treat a `user_guide/` document as a policy/contract authority.

## 8. How humans should navigate docs

Start from `docs/user_guide/` for operating and evaluating the tool, and `README.md` (repo root) for the high-level overview. For "what is done / what remains / what to do next," ask the agent for an on-demand status briefing (`docs/policies/DOCS_OPERATING_MODEL.md` §6) or read per-system `docs/systems/*/STATUS.md` directly; there is no committed project-current summary file.

## 9. What not to do (orientation)

In short: do not place execution policy under `user_guide/`, artifact contracts under `policies/`, or task-scoped/conditional policy into always-on priming; do not leave any markdown at `docs/` root except this file; do not preserve a location merely because it was recently committed or heavily referenced.

→ Operative rule (the binding placement prohibitions): `rules/docs-working-model.md` (*Docs placement*).

## 10. The three complementary docs surfaces (orientation)

- `docs/README.md` (this file): the docs **structure/placement map** — what each layer is for. The binding placement rules are the operative rule `rules/docs-working-model.md` (*Docs placement*).
- `docs/current/REPO_READING_GUIDE.md`: per-question **read-first routing** (which document answers which question, and the reading-priority order on conflict) — orientation, not authority over the active surface.
- `rules/docs-working-model.md`: the docs **change/closeout process** operative rule (top-down flow, single-home, STATUS/BACKLOG shape, on-demand briefing, two-level closeout gate); its rationale/record is `docs/policies/DOCS_OPERATING_MODEL.md`.

On overlap, placement orientation is this file, question-routing is `REPO_READING_GUIDE.md`, and the binding placement + change/closeout rules are `rules/docs-working-model.md`.

## 11. Reference update rule when moving docs (orientation)

Moving or splitting a document requires updating every inbound reference and preserving / remapping any section anchors referenced elsewhere.

→ Operative rule: `rules/docs-working-model.md` (*Docs placement*, reference-update-on-move).

## 12. Historical preservation (rationale)

Superseded / historical material is preserved in **git history**, not maintained as current docs (there is no separate archive docs tree). Current docs stay compact and self-contained; when a past decision is still operationally relevant, the active doc states it directly rather than pointing at retained narrative.
