# brief Spec

## Header

**이 문서는 무엇인가.** brief 도메인의 **목표 상태 명세**(spec-of-record)다 — Brief 가 무엇이고, 어떤 active surface 가 그 행동을 소유하며, 어떤 경계가 항구적으로 유지되는지를 normative 문장으로 명세한다.

**이 체인이 끝나면 무엇이 되는가.** 이 spec 과 `brief_backlog.md` 가 brief 도메인의 live 표면이 되고, 구계열 brief 문서(contract·STATUS·DEFERRED)와 구형 routing 은 retire 되어 도메인이 `docs/brief/` 안에서 닫힌다.

**이 문서가 아닌 것.** 구현 절차서 아님 · operative authority 아님(behavior 는 active surface 가 소유하고 이 spec 은 명세·대조될 뿐) · 용어 정의의 home 아님(`rules/terminology-glossary.md`). 이 spec 은 mutation/commit/push 승인이 아니다(1회 진술).

## 목표 상태

**Brief 의 정체.** Brief 는 한 project 의 **유일한 durable restore source** 다 — 사용자가 명시적으로 복원을 요청할 때 읽는 단 한 자리이며, 여러 session 에 걸쳐 의미가 유지되는 compact durable project state artifact 다. session transcript·누적 대화·review 본문·evidence payload 는 본문에 inline 하지 않고 경로로만 참조하며, session 단위 잡담은 담지 않는다. Brief 는 shared human handoff 문서가 아니다 — 제 1 독자는 그 project 를 운영하는 operator, 제 2 독자는 명시적 복원 요청을 받은 AI agent 다.

**BF Level.** BF Level 은 경로가 아니라 **save/restore capability maturity** 다. Level 1/2(manual save/restore discipline — operator 가 trigger/approve/reject/discard 의 주체이고 agent 가 본문을 작성하며, 손편집 모델에 의존하지 않는다)가 현재 운영 수준이고, Level 3(deterministic writer·stale warning·session-start guidance 의 자동화)는 미구현 future work 로 `brief_backlog.md` 가 보유한다. 무요청 session-start restore-offer 는 Level 3 의 구성요소가 아니라 **폐기된** 기능이다.

**Workflow(skill 소유 행동).** save(checkpoint)·restore·update 는 **explicit-prompt only** 로만 trigger 된다 — situation trigger 와 무요청 제안은 없다. workflow 는 operator-mode 전용이며, reviewer mode 는 Brief 를 읽지도 요구하지도 않는다. 명시적 복원 요청 시 agent 는 canonical Brief 를 읽어 한국어로 restore point 를 요약(현재 상태·다음 단일 action·do-not-do·pending user decision)하고 확인 질문을 거쳐 사용자 확인 후에만 진행한다. canonical Brief 가 없으면 부재를 보고하고 진행 방법을 묻는다 — Brief 외의 재구성 source 를 제시하거나 임의로 새 Brief 를 작성하지 않는다.

**Heading set.** Brief artifact 는 canonical heading 8종(required: Current state / Last completed action / Current scope / Next single action / Do not do / Files to inspect first / Open risks / Pending user decision)과 optional 3종(Relevant artifacts / Carry-over / Notes)을 사용한다. 내용 없는 required heading 은 `none` 으로 채우고, 임의의 새 top-level heading 은 만들지 않는다. 이 heading set 의 seed 는 template 이, 검증은 `brief-check.ps1` 이 소유한다.

**Primitive 행동.** 세 source-side primitive 는 narrow 하다 — BF Level 3 capability 가 아니다.

- `brief-init.ps1` 은 ProjectRoot/ToolRoot 를 resolve 하고 `<ToolRoot>/templates/brief/BRIEF.md` 를 읽어 canonical 자리에 **한 번** seed 한다. 대상이 이미 존재하면 거부하고(no overwrite), 필요한 directory 는 생성하며, 본문 내용의 자동 생성은 하지 않는다(placeholder seed 만). 종료 코드는 file IO 결과만 반영한다.
- `brief-check.ps1` 은 read-only 로 Brief 의 **shape 만** 검증한다 — required heading 8종의 존재, duplicate 거부, 본문 비어있지 않음(`none` 도 본문), `{{TOKEN}}` 형 미치환 placeholder 와 template sentinel 잔존 거부. 명시 path 인자는 ProjectRoot 안쪽이어야 하고, 대상 부재는 FAIL(비 0 종료)이며, 어떤 파일도 변경하지 않는다.
- `brief-status.ps1` 은 read-only 로 존재 여부를 확인하고 shape 검증을 `brief-check.ps1` child process 에 위임해 그 출력에 prefix 를 붙여 그대로 전달한다. shape FAIL 이면 그 종료 코드를 전달하고 요약을 내지 않으며, PASS 면 required heading 8종 각각의 첫 비어있지 않은 본문 줄을 Korean label 과 함께 출력한다. stale heuristic(mtime·HEAD 대조 등)을 도입하지 않는다.

**Self-dogfooding.** 이 repo 가 자기 자신의 ProjectRoot 로 동작할 때 생기는 Brief instance 는 다른 target 과 동일한 종류의 operator-local runtime artifact 이며, source payload 도 install payload 도 아니다.

## Owner surface 지도

| active surface | 소유 행동 |
|---|---|
| `scripts/brief-init.ps1` | seed 행동 + canonical 자리의 **구체 경로 값** |
| `scripts/brief-check.ps1` | shape 검증 행동(heading·placeholder·sentinel 규칙의 기계 판정) |
| `scripts/brief-status.ps1` | restore-summary 행동(존재+위임 shape+heading 별 첫 줄) |
| `scripts/lib/encoding.ps1` | 통제된 파일 IO(`Read-Utf8`/`Write-Utf8NoBom`) |
| `templates/brief/BRIEF.md` | canonical heading set seed + 작성 guidance + replace-me sentinel |
| `snippets/claude-skills/ai-harness-brief/SKILL.md` | workflow(trigger 문안·save/restore/update 절차·operator/reviewer mode 경계); 발견은 skill description 이 소유 |
| `tests/brief-init.Tests.ps1` / `brief-check.Tests.ps1` / `brief-status.Tests.ps1` | 위 행동의 지속 검증 |

behavior 의 authority 는 위 surface 들이다(root *Final hard rule*) — 이 spec 은 명세하고 대조될 뿐이며, spec 과 구현이 어긋나면 행동 변경이 아닌 한 spec 이 정정 대상이다.

## Durable boundary

- **canonical 자리는 단일하다**(class invariant — 이 spec 소유): project-local·operator-local·source-control-excluded runtime artifact 로 `<ProjectRoot>/log/` runtime 트리 아래 한 자리뿐이고 fallback 이 없다. 구체 경로 값은 active surface(scripts)가 소유하며 현재 값은 `<ProjectRoot>/log/brief/BRIEF.md` 다(1회 명시; 검증은 구현 대조). root `<ProjectRoot>/brief/` 와 user-home operator-local runtime root 는 **rejected** 이며, 다른 어떤 자리도 canonical 의 동의어로 부르지 않는다.
- **Brief 는 유일한 restore source 다.** 복원 흐름에 Brief 외의 source 를 도입하지 않는다.
- **default 는 untracked 다** — `<ProjectRoot>/log/` 는 gitignored runtime 트리이고 Brief 는 commit/push/merge/release 대상이 아니다. **tracked 전환은 이 spec 이 정의하지 않는 별도 operator decision 이다**(열린 경계 — 전환 방식·범위는 그 결정에서 정한다).
- **손편집 모델에 의존하지 않는다.** operator 는 trigger/approve/reject/discard 의 주체이고 본문 생성·갱신은 agent 또는 deterministic tooling 이 담당한다.
- **금지(BF Level 3 의 이름으로도)**: daemon · watcher · scheduler · hook · background process · `BF_STATE.json` 류 별도 state-machine 파일 · automatic decision-maker · 무요청 session-start restore-offer 의 부활.
- **primitive 의 금지**: `.gitignore` 변경 · 글로벌 파일(`~/.claude/`, root `CLAUDE.md`/`AGENTS.md`) 변경 · commit/push/publish/merge/release 실행 · Brief 본문 자동 보정(auto-fix loop) · snapshot/manifest/handoff 생성.
- **review 와의 비경계**: Brief 는 review subsystem 의 input 도 output 도 아니고 commit/push/release gate 가 아니다. `brief-check.ps1` 의 PASS/FAIL 은 shape 결과일 뿐 verdict(`yes`/`no`/`yes with risk`) 축과 서로 enforcement 하지 않는다.
- **multi-Brief orchestration(한 project 안 복수 Brief)·자동 retention/prune·transcript 자동 capture·BRIEF 요약의 commit message 자동 삽입은 도입하지 않는다.** 새 wrapper/CLI 가 도입되어도 canonical 자리·heading set·세 primitive 의 책임 경계는 default 로 유지된다.
- **encoding**: Brief artifact 는 UTF-8 without BOM 이고, primitive 의 파일 IO 는 `scripts/lib/encoding.ps1` 의 함수만 사용한다.

## Cross-domain interface

- **install-update (footprint 경계)**: target project 의 persistent footprint 는 `<ProjectRoot>/log/` 하나이고 Brief 는 그 아래 runtime artifact 다 — payload/install 은 Brief 를 포함하지 않는다. `INSTALL.md` 의 Brief 언급은 intentional contextual duplication 으로 존중한다(이 spec 이 회수하지 않는다).
- **ToolRoot (template 공급 인터페이스)**: `brief-init.ps1` 은 `<ToolRoot>/templates/brief/BRIEF.md` 를 읽는다 — ToolRoot 해석(채널 순서)은 install-update 도메인 소유이고 이 spec 은 그 경로 인터페이스만 의존한다.
- **글로벌 배포 티어**: snippets(글로벌 managed block)는 Brief framing 을 carry 하지 않는다 — Brief 의미의 home 은 이 spec 과 skill 뿐이다.
- **terminology**: 용어 의미는 `rules/terminology-glossary.md` 가 single home 이다 — 이 spec 은 accepted 용어를 일관 사용할 뿐 재정의하지 않는다.

## Validation expectation

- `tests/brief-init.Tests.ps1` · `tests/brief-check.Tests.ps1` · `tests/brief-status.Tests.ps1` PASS 가 성립해야 한다(primitive 행동의 지속 검증).
- 이 spec 의 normative 문장은 구현에서 확인 가능해야 하고(방향 1), 구현의 외부 관찰 가능 행동·소유 경계 변경은 spec 문장 변경을 동반해야 한다(방향 2; spec 문장 변경이 불필요한 구현 변경은 리팩토링). 대응 근거의 기록처는 closeout report / `log/evidence/**` 다.
- Brief artifact 와 `.md` 표면은 UTF-8 no BOM + LF, `.ps1` 표면은 repo 정책(UTF-8 BOM + CRLF, `scripts/verify-ps1.ps1`)을 따른다.

## Review focus

- 이 spec 이 **목표 상태 명세로 유지되는가** — 회차 candidate 목록·실행 시퀀스·staging·readiness 판정·시점성 상태가 유입되지 않는가.
- **single home 유지** — Brief 의미가 spec 밖에서 재진술되지 않는가(타 표면은 interface 참조만), spec 과 다른 표면 사이 이중화가 재발하지 않는가.
- **concrete path 문안** — canonical 자리의 구체 값이 active surface 소유의 현재 값으로 읽히는가(spec 의 path 소유로 격상되지 않는가).
- **workflow 경계 보존** — skill 변경 시 explicit-prompt only·무요청 제안 금지·reviewer-mode 배제가 유지되는가.

## Lifecycle state

- lifecycle 문서: 없음 — batch B closeout 에서 design / plan / work packet 은 retire(삭제)되었고 기록은 git history 가 보존한다.
- spec ↔ implementation: **live** — behavior 표면(scripts·template·skill·tests)과 문서 표면(routing·backlog·inbound pointer)이 이 spec 과 1:1 동기화되어 있다. 이후의 변경은 live-Spec 갱신(sync-required 전이) 규칙을 따른다.
- capability maturity: BF Level 1/2 운영 중(primitive 는 target 에서 operable); Level 3 후보 항목과 ID 발번(next ID)의 single home 은 `brief_backlog.md` 다(본 spec 은 pointer 로만 참조).
