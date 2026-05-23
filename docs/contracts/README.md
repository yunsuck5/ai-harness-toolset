# docs/contracts/ — Artifact and Protocol Contracts

This folder holds the **artifact / protocol contracts**: the format and validity rules for the toolset's produced artifacts and protocols. A contract defines the shape of a thing (its schema, valid/invalid output, validation criteria), not how or when an operator runs it.

## Access pattern

Read a contract when you are **producing or validating that specific artifact/protocol**. The contracts are partitioned by subsystem so that a task touching one artifact does not pull in unrelated contract scope.

| Subfolder | Contract | Read when |
|---|---|---|
| `review/` | `REVIEW_RESULT_CONTRACT.md` | producing/validating a review record (`input.md` + `result.md`, verdict) |
| `brief/` | `BRIEF_CONTRACT.md` | working with the Brief artifact (canonical location, BF Level, primitive boundary) |
| `chatlog/` | `CHATLOG_CONTRACT.md` | working with Chatlog (responsibility, Brief↔Chatlog boundary) |
| `evidence/` | `EVIDENCE_CONTRACT.md` | capturing evidence |
| `global-invocation/` | `SHARED_GLOBAL_INVOCATION_CONTRACT.md` | reasoning about ToolRoot/ProjectRoot resolution and shared/global invocation (D1–D9) |

`brief/` and `chatlog/` are coupled by the Brief↔Chatlog boundary; each cross-links the other rather than duplicating it.

## What does not belong here

Operator execution policy (→ `docs/policies/`), current system status (→ `docs/systems/<system>/STATUS.md`), roadmap/milestone routing (→ `docs/roadmap/`), and human-facing tutorials (→ `docs/user_guide/`). Per-subsystem `STATUS.md` documents route to these contracts as the authority; they do not replace them.
