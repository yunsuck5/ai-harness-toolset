# docs/user_guide/ — Human-Facing Guides

This folder holds **human-facing operation, evaluation, and adoption guides** — read when a person is learning to operate, evaluate, or adopt the toolset. These are release-facing in nature.

| File | Scope |
|---|---|
| `OPERATOR_GUIDE_KR.md` | Korean operator guide: ToolRoot/ProjectRoot modes, the natural-language review UX, BF save / explicit Brief restore UX, optional skill adoption, the operator command quickstart (fallback/debug), and the acceptance checklist. Sections that restate a contract (review artifact/verdict semantics, BF/brief/chatlog semantics) are kept as short pointers to the authoritative `docs/contracts/**`; the authoritative spec for the natural-language UX is `snippets/claude-skills/ai-harness-review/SKILL.md`. |
| `GLOBAL_ADOPTION_PROCEDURE.md` | Claude-skill global adopt / update / remove procedure. |

## Access pattern and boundary

Read these when **a human operates or evaluates the tool**. A `user_guide/` document is **not** a policy or contract authority: AI/operator execution policy lives in `docs/policies/`, artifact/protocol contracts in `docs/contracts/**`, question→authority routing in `docs/current/SOURCE_OF_TRUTH.md` (current progress / next action is answered on demand — `docs/policies/DOCS_OPERATING_MODEL.md` §6), and active decisions in `docs/decisions/`. Where this guide summarizes those, it points to them rather than redefining them.
