# Reviewer Config Policy

## Config location

The effective reviewer config is `<ToolRoot>/config/reviewer.json`, where `<ToolRoot>` is resolved per invocation (see `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`). `review-prepare.ps1` reads it from the resolved ToolRoot.

| Role | Path |
|---|---|
| Canonical source config | `config/reviewer.json` in the ai-harness-toolset source repo. In shared/global mode this is the build input materialized into the resolved runtime ToolRoot. |
| Effective config — shared/global mode | `<ToolRoot>/config/reviewer.json` of the resolved runtime ToolRoot (for example, the global stable install). This is the current adoption shape. |
| Effective config — legacy project-local copy mode | `<project-root>/.ai-harness/config/reviewer.json`. This path applies only to the legacy project-local copy mode, not to current shared/global adoption. |

The adjacent schema `config/reviewer.schema.json` documents this file's keys regardless of which ToolRoot resolves it.

## Precedence

```
model:           explicit -Model  > matched categoryPolicy entry `model`           > config/reviewer.json `model`           > FAIL-FAST (no built-in model default/fallback)
reasoningEffort: explicit -Effort > matched categoryPolicy entry `reasoningEffort` > config/reviewer.json `reasoningEffort` > policy safe-default `xhigh`
```

The matched-category tier appears only when the operator passes `-EffortCategory <key>` AND that key is present under `config/reviewer.json` `categoryPolicy` (U9). A category that is supplied but not present is a **soft miss** — resolution falls through to the scalar config tier (observable as `effort-policy-match: missed`), it does not fail. There is no automatic category selection: the operator chooses the category explicitly (the config supplies the mechanical `{model, reasoningEffort}` for it). See "Category policy (`categoryPolicy`)" below.

## Defaults

- Reviewer model: **no built-in default or fallback.** The model is the config source-of-truth (`config/reviewer.json` `model`, or an explicit `-Model`); if it is absent or empty, `review-run.ps1` and `review-safety-negtest.ps1` **fail fast** before invoking Codex. A concrete model version (a specific released model identifier) is tied to an external lifecycle, so it is never hardcoded as a default/fallback — that would silently mask a missing source-of-truth. `fallbackModel` is not auto-used.
- Default reasoning effort: `xhigh` — the safe default adopted in `docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md` (default = latest model + xhigh) and wired into `review-run.ps1` as of Batch B (`docs/systems/review/REVIEW_POLISHING_BATCH_A_SPEC.md`). The resolved effort is passed to the Codex CLI as `-c model_reasoning_effort=<value>`. (This supersedes the earlier `medium` default for the review subsystem's own self-review.)
- Only clearly-simple `local correctness review` packets downgrade below the safe default, via an explicit `-Effort` or a deliberately-tuned `categoryPolicy` entry (operator judgment). `system coherence review`-heavy, contract-sensitive, boundary-sensitive, and ambiguous work stays at high/xhigh. effort ⟂ coverage: a lower effort never substitutes for narrower coverage, missing evidence, or a weaker packet.
- **Category policy ships at the safe floor.** The `categoryPolicy` map (below) is shipped with **every** category at the safe default (latest model + `xhigh`); per-category effort/model VALUE tuning below the floor is deliberately deferred until first-cycle operational data (decision record U9: 세부 category 는 운용 데이터 후). Adding the map is the mechanism (config-backed lookup + per-invocation override); lowering any category's effort is a separate, deliberately-reviewed step.
- Allowed effort values (current reviewer tool, Codex CLI): `none`, `minimal`, `low`, `medium`, `high`, `xhigh`. An out-of-set value fails fast in `review-run.ps1` (no silent fallback).
- This config-driven default does not by itself establish `U9 operational`; that also requires the Batch C reviewer-safety verification (`docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md` §U10 hard gate, which scopes reviewer-safety into the combined first hard gate).

## Constraints

- Reviewer model and effort must remain config-driven.
- The reviewer **model** must never be hardcoded in a script as a default/fallback — it comes only from config (or an explicit `-Model`), and a missing/empty model fails fast (no silent fallback). The reviewer **effort** has a single policy safe-default (`xhigh`) that is an allowed built-in default; `timeoutSeconds` / `sandbox` are handled per their rows below.

The bullets above state the intended policy direction. The section below records the current as-built enforcement status, which does not yet match that intent for every key.

## Config key schema and enforcement status

`config/reviewer.json` must stay pure JSON with no comments. The per-key documentation lives in the adjacent schema `config/reviewer.schema.json`, which carries a `description` for every key covering its nominal meaning, where it is read, and its current runtime enforcement status.

Current as-built status of each key (in terms of the canonical operator-facing flow — config → Codex invocation / `input.md`):

| key | status |
|---|---|
| `model` | **Enforced + required** — passed to the Codex CLI as `--model`. Precedence: explicit `-Model` > matched `categoryPolicy` entry `model` (U9; optional per entry — absent ⇒ next tier) > `config/reviewer.json` `model` > **fail-fast** (no built-in model default/fallback; an absent/empty model fails fast before Codex is invoked, in both `review-run.ps1` and `review-safety-negtest.ps1`). |
| `provider` | Metadata-only — informational; not passed to the Codex invocation. |
| `fallbackModel` | **Dead / legacy — removal candidate.** Not present in the current `config/reviewer.schema.json` (`additionalProperties: false`), read by no script, and **never auto-used as a model fallback** (model resolution fails fast instead). Retained here only as a historical note. |
| `reasoningEffort` | **Enforced** — read by review-run.ps1 and passed to the Codex CLI as `-c model_reasoning_effort=<value>` (Batch B; previously metadata-only). Precedence: explicit `-Effort` CLI parameter > matched `categoryPolicy` entry `reasoningEffort` (U9) > this scalar value > built-in safe default `xhigh`. Allowed values `none`/`minimal`/`low`/`medium`/`high`/`xhigh`; an out-of-set value fails fast (no silent fallback) whatever its source (`source: explicit` / `config` / `category`). The applied effort is captured as a run-fact from the Codex stderr header and reported by review-run as `applied-effort:` (`not-observed` when the header is absent). |
| `categoryPolicy` | **Enforced (U9)** — optional config-backed `category → {model, reasoningEffort}` lookup, selected per-invocation by `review-run.ps1 -EffortCategory <key>`. Read by review-run.ps1; a matched entry supplies `reasoningEffort` (and optionally `model`) at the matched-category precedence tier above. A supplied-but-absent key is a **soft miss** (falls back to the scalar config; `effort-policy-match: missed`); a matched entry with an out-of-enum `reasoningEffort` fails fast (`source: category`). No automatic category inference (not from changed files / `-Stage` / LLM). Schema is portable (`config/reviewer.schema.json`): the category key set + per-entry values are per-project tunable; this batch ships all canonical categories at `xhigh`. See "Category policy (`categoryPolicy`)" below. |
| `sandbox` | Metadata-only — informational; the reviewer-safe invocation hardcodes `--sandbox read-only` (plus `--ask-for-approval never` and `--ignore-user-config`). See "Reviewer-safe invocation" below (Batch C). |
| `timeoutSeconds` | **Metadata-only / unenforced** — see below. |
| `outputFormat`, `resultFile` | Dead config — read by no script. |

> The canonical operator-facing artifact set is exactly `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` + `result.md` (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`). Current scripts emit this canonical layout directly; sidecar files outside that pair (for example `meta.json`, `target-files.list`, `result.json`) are not produced on the operator path and are not part of the contract. Historical references to those removed-legacy artifacts are preserved in git history and are not operator paths.

### `timeoutSeconds` status

`timeoutSeconds` is currently **metadata-only and unenforced**. The single-shot run executes the Codex CLI with no process timeout, so the value does not bound the Codex review process.

`timeoutSeconds` is explicitly **not**:

- a review quality or completeness guarantee — review validity is judged by the canonical artifact pair (`input.md`, `result.md`) and the deterministic gates listed in `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §4;
- the Claude Code harness tool timeout — that is a separate harness-level value that governs the shell tool call and can trigger harness auto-background conversion;
- a background-conversion control — it has no effect on whether a run is foregrounded or backgrounded.

Whether to enforce, demote to explicit metadata-only, or remove `timeoutSeconds` is a separate future decision tracked as review backlog candidate RV-B-02 (`docs/systems/review/BACKLOG.md`). This document does not decide it.

## Category policy (`categoryPolicy`)

`categoryPolicy` is the config-backed `category → {model, reasoningEffort}` lookup (U9; decision record "Script / config candidate decisions"). It splits cleanly along the decision-record judgment/mechanism line:

- **classification = operator judgment** — the operator decides which category a change is and passes it explicitly: `review-run.ps1 -EffortCategory <key>`. There is **no** automatic category inference (not from changed files, not from `-Stage`, not LLM-based).
- **mapping = config mechanical lookup** — `config/reviewer.json` `categoryPolicy` supplies the `{model, reasoningEffort}` for that key.
- **application = runner** — `review-run.ps1` applies the matched entry at the matched-category precedence tier.

Entry shape (`config/reviewer.schema.json` `$defs/categoryEntry`): `reasoningEffort` is **required** (allowed values as above); `model` is **optional** — when present and non-empty it overrides the scalar `model` for that category (`model-source: category`), when absent the scalar `model` applies (a deliberate simplicity choice so a project can tune effort alone; no new model fail-fast is introduced for a matched-but-model-less entry). Strict shape: no other keys per entry.

**Fail-fast vs fallback:**

- **Soft fallback (no failure):** `effort-policy-match` is determined by **key presence**. A `-EffortCategory` key that is genuinely **absent** from `categoryPolicy` (or a config with no `categoryPolicy` at all) → `missed` → resolution falls through to the scalar `model` / `reasoningEffort`. This keeps a downstream project whose config predates `categoryPolicy` working unchanged. (`missed` is reserved for a genuinely absent key — a present key is always `matched`, even if its value is malformed.)
- **Fail-fast (config error):** a **matched** category entry (key present) is authoritative for effort — `reasoningEffort` is required for an entry — so a matched entry that is malformed fails fast before any Codex invocation rather than silently falling back to the scalar default (which would hide a category-config typo behind `effort-policy-match: matched`). The malformed cases: out-of-enum effort (`review-run: FAIL invalid reasoning effort '<v>' (source: category)`); missing/empty effort (`review-run: FAIL matched effort category '<key>' has no usable reasoningEffort ...`); a present key with a **null** entry value, e.g. `"<key>": null` (`review-run: FAIL effort category '<key>' is present ... but its entry is null ...`). (A category `model` is optional and *does* fall back to the scalar `model` when absent — only `reasoningEffort` is mandatory for a matched entry.)

**Schema portability + safety floor.** The schema is project-independent: the category KEY set and per-entry VALUES are per-project tunable (`additionalProperties` is a strict `categoryEntry`), while the canonical key set is documented in the schema. The shipped set is intentionally **generic** — universal software change classes — so the same global-install config is portable across projects; project-specific categories are deliberately **not** shipped (a project may add its own keys locally). The shipped `config/reviewer.json` sets **every** category to the safe default (latest model + `xhigh`); lowering any category's effort below the floor is a separate, deliberately-reviewed value-tuning step gated on first-cycle operational data (decision record U9). The 12 canonical generic categories: `default`, `simple-local`, `medium-scope`, `complex-broad`, `system-coherence-heavy`, `contract-sensitive` (covers API / interface / schema / machine-readable-output / parser-gate contracts), `boundary-sensitive`, `script-runtime`, `test-code`, `mechanical-audit`, `docs-planning`, `docs-wording`.

> Note: a category **miss** falls back to the scalar `model` / `reasoningEffort`, **not** to the `default` category entry. The `default` entry is used only when `-EffortCategory default` is passed explicitly.

## Output location

Reviewer output lives under `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` — the canonical two-level layout that current scripts emit directly (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`). A root `codex-review-input.md` or `codex-review-result*.json` is forbidden.

## Reviewer boundary

- `-Reviewer codex` is the only supported reviewer.
- The canonical review entry is the two-step `scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>]` → AI authors the pass `input.md` at `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` → `scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` flow. Codex CLI is invoked exactly once per `review-run.ps1` call.
- `fallbackModel` is dead/legacy (not in the current schema, read by no script, never auto-used as a model fallback); reviewer model resolution fails fast on a missing/empty config `model` rather than falling back.
- reviewer verdict is not approval for commit / push / publish / merge / release / deployment.

Canonical artifact set and verdict semantics are defined in `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`.

## Reviewer-safe invocation

The reviewer invocation must not depend on a permissive global reviewer-tool config for its safety. `review-run.ps1` enforces a reviewer-safe posture explicitly on every Codex invocation (Batch C of the review-system polishing implementation plan):

- `--ask-for-approval never` — no interactive approval / un-sandboxed escalation.
- `exec --sandbox read-only` — the model cannot write the source tree / review target.
- `--ignore-user-config` — the reviewer tool's `$CODEX_HOME/config.toml` is **not loaded**, so operator-convenience permissive settings there (e.g. `sandbox_mode = danger-full-access`, `approval_policy = never`) cannot weaken the explicit flags above. Auth still uses `$CODEX_HOME`. This makes the reviewer-safe posture **structural** (the permissive config is absent) rather than dependent on flag-precedence over a loaded permissive config.
- result artifact: written via the runner-controlled `--output-last-message` channel, **not** by a model-initiated source-tree write.

**Trade-off of `--ignore-user-config` (disclosed):** it drops *all* of `config.toml` except auth. Everything `review-run.ps1` needs — model, reasoning effort, web_search, sandbox, approval — is passed explicitly, so dropping `config.toml` does not change review behavior. The residual risk is portability: a user whose `config.toml` sets a custom model provider / base URL (not passed by review-run) would have it dropped, and the review would use the default provider for `--model`. MCP servers / plugins / notify hooks in `config.toml` are operator-interactive conveniences not needed by a non-interactive read-only `codex exec` review.

**Verification status (honest):** reviewer-safe precedence/enforcement is **verified for the tested write vectors only** (source-tree create, tracked-file modify, existing-file modify) under the environment's actual permissive global config, via `scripts/review-safety-negtest.ps1` — corroborated by both the model's report and an independent filesystem check. It is **not a blanket guarantee**: untested vectors (arbitrary binary exec, network egress, alternative write APIs), other platforms, and other reviewer-tool versions remain limitations. If a tested vector's write ever lands, the negtest reports `fail` / not-verified (no silent pass). reviewer-tool-specific: re-derive if the reviewer tool changes.

## Run-fact reporting (review-run stdout)

On a successful run, `review-run.ps1` emits single-invocation run-facts to stdout for operator debugging (Batch B + Batch D2). These are H1 run-facts — facts deterministically observable from one invocation. They are **not** the operator's final human report: perspective coverage, invocation / artifact-pass / corrective-loop counts, and the commit/push recommendation are H2 fields the runner does not emit.

- `verdict:` — the parsed `## Verdict` value.
- `model:` / `model-source:` — the resolved reviewer model (the runtime-resolved value, never a concrete version hardcoded in docs/scripts) and the actual resolver branch (`explicit` for `-Model`, `category` for a matched `categoryPolicy` entry's `model`, `config` for `config/reviewer.json`). A missing/empty model fails fast before this line (no built-in fallback).
- `requested-effort:` / `effort-source:` / `applied-effort:` — the Batch B effort run-facts (`applied-effort: not-observed` when the Codex stderr header is absent). `effort-source` is the actual resolver branch: `explicit` / `category` / `config` / `default`.
- `effort-category:` / `effort-policy-match:` — the U9 category run-facts. `effort-category` is the operator-chosen category (`none` when `-EffortCategory` was not supplied). `effort-policy-match` is the lookup outcome: `none` (not supplied) / `matched` (key present in `categoryPolicy`) / `missed` (supplied but absent → scalar fallback). `effort-source` / `model-source` report the actual winning tier per axis (explicit `-Effort` / `-Model` win per axis even when a category matched). So on a `matched` category: `effort-source` is `category` unless an explicit `-Effort` overrides it (then `explicit`); `model-source` is `category` only when no explicit `-Model` overrides **and** the matched entry carries a `model` (otherwise `explicit` for `-Model`, or `config` — a category `model` is optional).
- `reviewer-safe-posture:` — the structural safety flags actually passed on this invocation (`--ask-for-approval never --sandbox read-only --ignore-user-config web_search=disabled`). This line is the **posture flags only, not a blanket safety guarantee** — the tested-vectors-only "Verification status" caveat above still governs; the stdout line makes no guarantee claim.
- `tool-root:` / `project-root:` / `tool-root-source:` — the engine ToolRoot, the ProjectRoot, and the ToolRoot resolution source (`explicit` / `implicit`) the runner actually resolved. These are operator-debugging run-facts, not source-of-truth claims.

## Diagnostic Codex invocation reference

For diagnosing Codex CLI invocation compatibility, the equivalent command shape (matching what `scripts/review-run.ps1` runs internally against the canonical pass directory) is:

```powershell
# Paths below use the canonical <review-task-id>/pass-NN/ layout per
# docs/contracts/review/REVIEW_RESULT_CONTRACT.md.
Get-Content -Raw -LiteralPath "log/review/<review-task-id>/pass-NN/input.md" |
  codex --ask-for-approval never exec --sandbox read-only --ignore-user-config --model <model> -c web_search=disabled -c model_reasoning_effort=<effort> --output-last-message "log/review/<review-task-id>/pass-NN/result.md" -
```

The normal path for a completed review record is the two-step `review-prepare.ps1` + `review-run.ps1` flow. The canonical contract is `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`.
