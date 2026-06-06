# docs/architecture/ — Cross-Cutting Architecture Decisions

This folder holds **cross-cutting architecture decisions / audits** that span multiple subsystems and surfaces and that decide a structural target **before** implementation. Read when reasoning about how the toolset's surfaces are partitioned as a whole, not about one subsystem's current state.

## Access pattern

Read an architecture doc when a task touches **how a structural concern is divided across surfaces** (e.g. which instruction tier owns which rule). Partitioned by architecture concern so one concern's planning does not pull in unrelated scope.

| Subfolder | Concern | Read when |
|---|---|---|
| `instruction-surface/` | `INSTRUCTION_SURFACE_PLAN.md` — how operating rules are partitioned across instruction tiers (global instruction / repo-local always-on instruction / skill `description` / `SKILL.md` / `docs/contracts` / memory / hooks; Codex Rules excluded); `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` — the plan's Track B per-section classification of the remaining global snippet content; `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` — the plan's Track C decision (track root `CLAUDE.md` / `AGENTS.md`) + implementation spec | planning or auditing the instruction/capability surface split |

## How this differs from `docs/systems/`

- `docs/systems/<system>/` answers **"what is one implemented subsystem's current operational posture?"** (STATUS / BACKLOG / DEFERRED + that subsystem's operating model). It is per-subsystem and describes existing state.
- `docs/architecture/<concern>/` answers **"what is the target structure for a concern that spans several subsystems/surfaces, decided before implementation?"** It is cross-cutting and design-stage. It does not own any subsystem's current state — it points at `docs/systems/**` for that.

It also differs from `docs/decisions/` (discrete settled decision records) by being multi-surface *planning/audit* with classification criteria and option analysis, not a single terminal decision.

## What does not belong here

Per-subsystem current status (→ `docs/systems/<system>/STATUS.md`), artifact/protocol contracts (→ `docs/contracts/`), execution policy (→ `docs/policies/`), and settled decision records (→ `docs/decisions/`). An architecture doc **routes to** these as the authority; it does not replace them. Always-on rules still belong in an always-on instruction surface — the global snippet/payload, or (for repo-only always-on rules) a planned repo-local instruction surface — **never** under `docs/` (`docs/README.md` §4).
