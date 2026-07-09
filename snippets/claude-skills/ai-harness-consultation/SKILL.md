---
name: ai-harness-consultation
description: Owns the ai-harness-toolset consultation workflow — collecting read-only opinions, counterpoints, and investigation from one or more consultants (an external AI or a sub-agent) BEFORE the operator judges, approves, or mutates, then folding them into an operator synthesis. Two framing-axis operations, named by their user-facing Korean triggers - `독립 의견` (id `independent`, pre-focus independent opinion, one-shot) and `재조율` (id `reconcile`, stance-sharing adversarial reconciliation, multi-round). Trigger on natural-language intents to get an independent or adversarial read-only take before deciding — e.g. "코덱스한테 이거 독립 의견 받아줘", "이 지점 재조율 돌려줘", "카운터포인트 받아줘", "다른 AI 의견 받아서 종합해줘", "get an independent read-only take on this", "run an adversarial reconciliation on my draft". Advisory only — it issues NO verdict and approves no commit / push / release / adoption. Do NOT trigger for a canonical code review (that is `ai-harness-review`), a changeset defect prefilter (blind advisory — a separate layer), Brief save / restore (`ai-harness-brief`), or ordinary work.
---

# ai-harness-consultation

This skill owns the ai-harness-toolset **consultation** workflow: the operator delegates **read-only** opinion, counterpoint, or investigation to one or more **consultants** (an external AI or a sub-agent) *before* judging, approving, or mutating anything, and then folds the responses into an **operator synthesis**. Discovery / trigger is owned by this skill's `description`.

Consultation is **advisory governance, not a gate**. It issues no verdict, it approves nothing, and it never substitutes for another domain's source of truth.

## What this is not

- **Not canonical review.** The review verdict gate (`yes` / `no` / `yes with risk`) is `ai-harness-review`. Consultation never emits a verdict.
- **Not blind advisory.** Blind advisory is a separate layer that *removes* operator framing to prefilter changeset defects. `재조율` *provides* framing. Opposite operating principles — do not merge them.
- **Not Brief, not implementation delegation, not general research or debate, not "every AI call", not every sub-agent orchestration, and not a substitute for evidence / validation / approval.**

## Core invariants

These bind every consultation run.

- **Read-only.** A consultant inspects only; it never mutates. If mutation or a separate approval becomes necessary mid-consultation, **stop at that point** and escalate (see *Read-only escalation*).
- **Advisory only · no verdict.** Consultation output approves no commit / push / release / adoption, and never carries the review verdict vocabulary.
- **Operator synthesis is mandatory.** A consultant response never becomes source of truth on its own. The operator folds responses into concerns / hypotheses / alternatives / verification questions.
- **A consultant is not a truth oracle.** Facts about timing, procedure, and document wording are re-verified by the operator **against the original text** before being carried into any output — *a citation can be fully accurate while the concept it is said to express is not.*
- **Secret / redaction minimum.** When calling an external commercial AI, neutralize the input so sensitive material is not transmitted, and respect the transmission boundary. (This interfaces with the global security discipline; consultation does not own it broadly. Detailed redaction mechanism and transmission-approval policy are backlog.)
- **Vocabulary separation.** Never mix review's `verdict` / `pass` / `finding` vocabulary, nor blind advisory's `concern` vocabulary, into consultation output.
- **Other domains by interface only.** Anything handed to another domain goes through that domain's own interface, neutralized by the operator.
- **No-file runtime.** Consultation itself creates **no per-run input / output files**. It runs as conversational synthesis. (This is the opposite of the canonical review's `input.md` / `result.md`.)

## The two framing-axis operations (exactly two)

The framing axis has exactly two named operations. They are **orthogonal to the packaging axis** — either can be carried by any packaging mode.

### `독립 의견` — id `independent`

Pre-focus independent consultation.

- **Input = question + background only.** The operator's stance, draft, or conclusion is **not** included.
- **Questions are constructed two-directionally** — both outcomes left open ("is X sufficient, or insufficient?"), never a premise-embedded question ("list the axes where X falls short"), which destroys pre-focus independence.
- **One run is one-shot and always terminal.** There is no round loop inside a run. If the operator calls again, that is a **new independent run**, not a continuation of the previous one.
- **Runs fresh** (zero anchoring). Do not resume a prior session for this operation.
- The request **may ask the consultant to self-report residual framing pressure**; the two-directional question form is what makes that self-report possible.
- Value is highest **before** the operator's focus is fixed — once a draft exists, the synthesis is already biased.

### `재조율` — id `reconcile`

Stance-sharing adversarial reconciliation.

- **Input requires the operator's in-progress stance / draft.** The point is to have it attacked and aligned.
- **Multi-round, with no fixed round cap.** The **operator is the circuit-breaker** — the operator, not the consultant, decides convergence and termination. A consultant never self-terminates the loop.
- **Runs session-persistent by default.** Re-packaging the accumulated context every round would load the operator's bias into it; persistence removes that surface.
- The operator **appends an independent evaluation** at the end and **never verbatim-transports** the other side's opinion as if it were the operator's own reading.

### `재조율` loop state

Loop state is a **wrapper value the operator attaches** to a `재조율` run. It is **not** a field the consultant emits.

| Loop state | Meaning |
|---|---|
| `needs_reply` | **Turn-terminal** — awaiting the operator's reply at a round boundary. **The loop continues.** |
| `converged` | Loop-terminal — the operator judges there is nothing further to contest at the advisory level. |
| `human_residual` | Loop-terminal — the operator hands the remaining unresolved matter to a person. |

**Never treat `needs_reply` as closure.** Taking one round of rebuttal and calling the consultation complete is an *incomplete* run. `독립 의견` has no loop state — it is one-shot terminal.

## Loop state and status vocabulary are separate axes — never merge them

- **Loop state** (above) controls *the loop of one `재조율` run*.
- **Status vocabulary** is the operator's classification of the advisory *output*: `synthesized` / `needs-follow-up` / `conflicting-opinions` / `insufficient-context`. This is consultation's own vocabulary, kept separate from review's verdict vocabulary and from blind advisory's status set.

`needs_reply` (loop) and `needs-follow-up` (status) are **similar in spelling and different in axis**. Do not collapse them into one field.

## Packaging axis (consultant topology)

`single-consultant` · `parallel-consultation` · `role-split-consultation` · `counterpoint` (counterpoint generation).

- `roundtable` (a second round of rebuttal after a first synthesis) carries a high cost / contamination risk and is a **follow-up candidate, not supported here**.
- `council` is **not a domain name** — it is a pending packaging alias.
- `counterpoint` (a packaging mode) is **not** the review result document's `Counter-argument` section. Different things.

## Constructing the request

- **The request owns the inspection scope.** The allowed scope spans inference-only (a lightweight discussion) through full-scope investigation (the consultant reads the target files directly). **Which point on that spectrum applies is decided by the request, explicitly — not by what the tool environment happens to permit.**
- **Providing a factual frame is not injecting a conclusion.** Supplying the target's layer, altitude, and role is a determinant of judgment accuracy, not framing contamination. What is forbidden is injecting a **conclusion or preference**. A factual frame and a stance are different things — this is compatible with `독립 의견`'s no-stance rule.
- Neutralize sensitive material; minimize inlining private paths or secrets.
- State the read-only boundary in the request itself.

## Advisory item shape

Each advisory item carries, in its own output, a **confidence** and the **assumption** it rests on.

## Conflict default = a `재조율` loop

When consultant responses conflict with each other, or a consultant rebuts the operator's draft, **the default is another `재조율` round (re-relay / re-question) — not a unilateral closure.**

- Stop and ask a person **only** when it is a *critical unresolved item that neither AI can answer*. The operator is the **external circuit-breaker**; there is no round cap, because a cap manufactures premature closure.
- **Convergence is advisory and authorizes no action.** Convergence is not commit / promote approval.
- **Fast, frictionless convergence is a warning signal, not a closure signal.**
- When rejecting a consultant's point, mark whether the basis is a repo invariant, a precedent, or an explicit convention.

## Read-only escalation

A consultant never mutates, never writes a verdict, never carries an approval decision, and never satisfies a gate condition.

If, during a consultation, it becomes clear that **mutation or a separate approval is required** to proceed:

1. **Stop the consultation at that point** — do not have the consultant perform or simulate the action.
2. Escalate **to the user**, stating: what mutation / approval is now required, why it surfaced, what the options are, and what remains unresolved.
3. Resume only on the user's explicit decision. The consultation itself never carries that decision.

## Operator synthesis — the required output shape

Present the run inline, in three parts:

1. **Operator position / question** — what was actually sent to the consultant.
2. **Consultant response** — undistorted, not paraphrased into agreement.
3. **Operator synthesis** — agreement / disagreement / correction / remaining decisions, plus the `status vocabulary` label.

Labels and state names must not acquire an approval smell. Never write "approved", "passed", "signed off", or any verdict token. The output of a consultation is an advisory input to the operator's own judgment.

## Consultant adapters

The behavior above is adapter-independent. Two consultant paths are supported:

- **Sub-agent consultant** — a delegated agent in the same harness.
- **External CLI consultant** (reference adapter: the Codex CLI) — invoked **read-only**, with the prompt passed on **stdin**, encoding fixed to UTF-8, and **no staging file** for the prompt. Keep the working directory neutral so the consultant does not drift into unprompted repo investigation; whether it reads target files is decided by the request (see *Constructing the request*).
  - `독립 의견` runs **fresh** (no session resume). `재조율` runs **session-persistent** across rounds.
  - When a resumed session does not inherit the original sandbox or working directory, the read-only sandbox and a neutral working directory must be **re-pinned explicitly on every resume**. A resume that silently falls back to a permissive sandbox is a boundary violation.
  - A transport sub-agent may wrap the invocation to preserve the main session's context. Its role is **verbatim return** — no filtering, summarizing, reinterpreting, or self-analysis. If a response cannot be returned inline in full, disclose that limit rather than silently truncating.

No adapter creates a durable per-run **functional** artifact at a repo / cwd / log policy path (*no-file runtime*). Two narrow, documented transport-layer exceptions exist — see *Reference invocation* below.

## Reference invocation (Codex CLI adapter)

Delivery disciplines that keep the External CLI adapter read-only, byte-safe, and no-file. Established through repeated dogfooding and confirmed by direct measurement. The core behavior above is adapter-independent; this is a reference for the Codex-CLI adapter specifically.

- **Delivery path.** Pass the prompt on **stdin via a here-document in a direct shell** (Git Bash / the harness Bash tool). Do **not** wrap the here-document in `bash -c '…'` — a single quote inside the prompt collides with the outer quoting and breaks the call (the failure is the wrapping, not the here-document). Do **not** stage the prompt in a file. `--sandbox read-only` is mandatory; keep the working directory neutral (`-C` at a temp dir) for pure-discussion calls.
- **Encoding.** Deliver UTF-8. The direct-shell here-document is byte-exact for Korean / CJK / accented / quote characters (measured: md5-identical round-trip). Do **not** rely on the Windows PowerShell pipeline (`$prompt | codex`): its default `$OutputEncoding` is US-ASCII, which **silently replaces every non-ASCII character with `?` at exit 0**; if that path is unavoidable, pin `$OutputEncoding` (and the console encodings) to UTF-8-no-BOM on **every** call (shell state does not persist). When the consultant reads non-ASCII files itself, direct it to read as UTF-8 (a default read may decode as CP949 and corrupt).
- **Delimiter.** Use a here-document delimiter that does not appear as a standalone line in the prompt — a bare delimiter line inside the payload terminates the here-document early and injects the remainder as shell commands. Because the operator authors the prompt, this is excluded by scanning the payload. Use a **quoted** delimiter (`<<'EOF'`); an unquoted one runs parameter expansion and command substitution on the payload.
- **Length.** Do not inline large content — point the consultant at what to read (per *Constructing the request*) rather than pasting it. The whole shell command carries an environment-dependent ceiling (observed ~8 KiB total argv in this harness — **not a guaranteed value**; quote-heavy payloads reach it ~5× sooner) above which the command **truncates silently**. Data streamed through a pipe has no such limit (the ceiling is on the command string, not on piped bytes). Binary / NUL content is out of scope (a here-document drops NUL); consultation is text-only.
- **no-file and its two documented exceptions.** Default: no durable per-run artifact at a repo / cwd / log policy path. Exceptions: (1) **file redirect** (`codex exec … - < file`) **only** when a direct shell is genuinely unavailable — the file lives outside policy paths (session scratchpad), is deleted immediately after the call, and its use is disclosed; (2) **large response transcript** — when a response is too large to return inline, a transport sub-agent may preserve it in a file and disclose the limit rather than silently truncating. Neither is a per-run *functional* artifact (the consultation itself stays no-file); both are transport-layer, bounded, and disclosed.
- **Transport sub-agent.** A transport sub-agent wrapping the call returns **verbatim** (no filtering / summarizing / reinterpreting), the main session **joins** the completed result, and it creates no file. On a timeout it **waits to completion** (raise the timeout, return in one report) — it must **not** leave the retry running in the background and report early (that creates a caller-visibility gap). One retry, then report `unavailable`.
- **Full-scope investigation vs neutrality.** When the consultant must read files directly, set `-C` to a root that **contains** those files (a neutral temp root places repo / external files outside the read-only sandbox and the read fails), and **explicitly permit** the read commands — a blanket "no command execution" instruction blocks the consultant's only file-read mechanism. Opening that root trades neutrality for access; for reading repo or external files, a Claude sub-agent using the harness read tools is the higher-recall, sandbox-independent path, while the CLI consultant is the independent-reasoning / external-perspective path.

## Durable boundary

**Allowed (standing):** read-only inspection · advisory output · operator synthesis · the two framing operations · the packaging modes · no-file conversational execution.

**Forbidden (standing):**

- issuing a verdict; approving commit / push / release / adoption; consultant mutation
- substituting for another domain's source of truth
- counting consultation into review invocation / pass / coverage
- storing a consultation transcript under `log/review/**`
- promoting consultation output into the source of truth for `Blocking findings`
- instructing a canonical reviewer to trust a consultation conclusion
- auto-inserting a consultation preflight into a canonical-only request
- broad-bucket expansion (every AI call · general research · every sub-agent orchestration · every operator decision aid)

## Cross-domain interface

- **review** — consultation connects only as review's **optional advisory preflight**; review does not own consultation's semantics. The operator hands over neutralized material in the form of review's own preflight-input interface (if that form changes, review's definition governs). Consultation references it and does not restate its internals. Review-skill integration is the last step on the roadmap.
- **subagent-work-orchestration** (still an incubating rule candidate — its formal owner surface exists only after promotion, and it is not a discovery / authority target today) — its close-the-loop JOIN guarantee is **name-referenced only**; its semantics are not restated here.
- **blind advisory** — a separate layer. Consultation does **not** take blind output as its input; the two combine only inside the operator synthesis (input-independent). `재조율` provides framing and blind removes framing, so their operating principles are opposite.

## Boundaries of this skill

- The first build target is a **deletable skill**: it makes no irreversible change to the canonical review or install surfaces.
- Rules name the class / invariant (read-only · advisory · no-verdict · vocabulary separation); this skill owns the behavior.
- Never run `git commit`, `git push`, `git tag`, `git merge`, or any release / publish command. Never modify user-global or project-root instruction files. Those are separate explicit user decisions.
