# docs/contracts/ — Artifact and Protocol Contracts

This folder holds the **artifact / protocol contracts**: the format and validity rules for the toolset's produced artifacts and protocols. A contract defines the shape of a thing (its schema, valid/invalid output, validation criteria), not how or when an operator runs it.

## Access pattern

Read a contract when you are **producing or validating that specific artifact/protocol**. The contracts are partitioned by subsystem so that a task touching one artifact does not pull in unrelated contract scope.

This layer currently holds **no live contract files** — the former contracts are absorbed into the domain specs:

- the former `global-invocation/` (`SHARED_GLOBAL_INVOCATION_CONTRACT.md`) is **absorbed into the install-update domain spec** — read `docs/install-update/install-update_spec.md` when reasoning about ToolRoot/ProjectRoot resolution and shared/global invocation channels (full history in git);
- the former `review/` (`REVIEW_RESULT_CONTRACT.md`) and `evidence/` (`EVIDENCE_CONTRACT.md`) contracts are **absorbed into the review domain spec** — read `docs/review/review_spec.md` when producing/validating a review record or capturing validation evidence (full history in git).

## What does not belong here

Operator execution policy (→ `docs/policies/`), current system status (→ per-domain spec lifecycle-state sections, or `docs/systems/skills/STATUS.md`), and roadmap/milestone routing (→ `docs/roadmap/`). The operative authority for active behavior is always the active surface a contract records — scripts / templates / skills / config / tests.
