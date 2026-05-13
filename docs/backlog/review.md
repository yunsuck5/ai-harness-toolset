# Review Backlog

본 파일은 review subsystem 및 review 운영 관련 open 후보 항목을 기록한다. 본 파일의 어떤 항목도 implementation, scheduling, release 의 자동 승인이 아니다. 본 파일과 다른 contract 문서가 충돌하면 contract 문서가 우선한다 (`./README.md` 참조).

---

## Review 2-pass / profile for user-facing instruction text

- **Status**: trial / candidate

### Context

`SHARED_GLOBAL_INVOCATION_CONTRACT.md` §6 step 3 / D4 (`snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md` 의 mode-neutral body rewrite) 진행 중, single-pass Codex review 는 contract / consistency 문제는 catch 했지만, "source-managed files always live under `<ToolRoot>`" 같은 **fresh adopter 시점의 reader-risk ambiguity** 는 single pass 에서 단정적으로 잡히지 않았다. 추가 supervisor 단계에서 발견되어 commit 전에 wording 보정 ("Toolset-owned source/config/template/snippet files live under `<ToolRoot>`. Target-owned project files and runtime artifacts live under `<ProjectRoot>`.") 이 이루어졌다.

latest related commit: `8234bf1 Align snippets with shared global layout`.

이런 reader-risk ambiguity 는 user-facing instruction (`snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md`, `snippets/claude-skills/**/SKILL.md`, 운영 가이드성 docs) 변경에 특히 자주 발생할 수 있다. handoff packet 에만 남기면 유실 가능하므로 repo-visible backlog 항목으로 보존한다.

### Trial

당분간 user-facing 변경에서는 **수동 2-pass review** 를 운용한다.

- **Pass 1 — contract review.** 현재의 single-pass Codex review 그대로. acceptance criteria, target artifact consistency, contract 충족 여부에 집중한다.
- **Pass 2 — reader-risk / adoption ambiguity review.** fresh target-project adopter 관점에서 semantic ambiguity 를 점검한다. 아래 checklist 를 input 으로 한다.

각 pass 는 별도 scoped 호출이며, 별도 run-id / 별도 `meta.json` / 별도 `result.md` / 별도 `result.json` 을 생성한다. 기존 result binding / freshness 검증 contract 는 그대로 따른다.

### Reader-risk checklist

본 checklist 는 trial 단계의 draft 다. 운영 중 다듬어질 수 있다. 모두 yes 일 필요는 없고, 검토자가 의미 ambiguity 후보를 명시적으로 점검하기 위한 prompt 다.

```text
[ ] Toolset-owned files, target-owned tracked files, runtime artifacts 의 구분이 명확한가?
[ ] "always", "only", "default", "source", "runtime", "global", "local" 등 강한 단어가 contract 가 보장하는 범위보다 넓게 사용되지 않았는가?
[ ] Project layout / Review flow / Brief / Chatlog / SKILL flow 사이에 semantic conflict 가 없는가?
[ ] Fresh target-project adopter 가 shared / global mode 와 project-local legacy mode 를 혼동할 만한 표현이 있는가?
[ ] Trigger phrase / 자연어 hook 의 source-of-truth 가 `SKILL.md` frontmatter 라는 점이 명확한가 (snippet body 의 illustrative aside 와 혼동되지 않는가)?
```

### Future decision

본 항목은 design contract 가 아니라 backlog 후보다. 실제 review data 가 한두 round 더 쌓인 뒤 다음 중 하나로 결정한다.

- documented two-pass convention 으로 유지한다.
- explicit CLI-only `ReviewProfile` 기능으로 구현한다.
- 사례를 더 쌓고 재평가한다.

### Non-goals

- daemon / watcher / background automation / implicit multi-run behavior 는 도입하지 않는다.
- 본 backlog 항목 자체는 어떤 구현도 자동 승인하지 않는다.
- `ReviewProfile` 구현이 미래에 채택되더라도, 그 implementation 은 별도 scoped 승인과 별도 review subsystem 변경 (`docs/roadmap/REVIEW_EFFORT_GUIDE.md` §4 의 review-required 항목) 을 거친다.
