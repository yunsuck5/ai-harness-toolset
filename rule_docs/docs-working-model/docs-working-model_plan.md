# docs-working-model Plan — prelive 정의 명확화

> Plan 은 **승인 대상인 의사결정만** 담는다 — 작업 메모가 아니다. 조사 결과·line 분류는 Work Packet 소관, 실행 기록은 operator report(`log/**`) 소관. Plan 이 Design 을 위반하면 stop → Design 재설계 후 재시작. Plan 은 영구 live 아님 — closeout 시 흡수 후 retire(삭제). 이 Plan 은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

- 이 문서는 위 Design(prelive 정의 명확화)의 **approval-target 결정 Plan** 이다 — E1 절 한 지점의 명확화를 단일 changeset 으로 landing 하는 결정.
- 이 체인이 끝나면 = terminal rule 의 E1 절이 not-authority marker 의 lifecycle 의미(verified-authority 소비 경계)와 active-surface 배포-경로의 경계를 명시하고, 이 Plan·Design 은 (지연된) closeout 에서 retire.
- 이 문서가 아닌 것 = 최종 normative wording 아님(terminal rule 소관) · 실행 기록 아님.

## Batch 순서와 의존

- **단일 changeset, 단일 sub-change**: E1 절 명확화 문장 추가. 분리할 것이 없다(수정 대상이 한 절).
- **지배 버전(Self-amendment 절 적용 — governance 조항 개정)**: pre-revision 규칙 텍스트가 **이 revision 자신의 lifecycle 행위**(landing, 그리고 지연된 closeout 의 retire 판단)를 지배한다. B 재리뷰·O promote 는 이 revision 에 속하지 않는 **별개 작업**이며 landing *이후 시작* 행위로서 새 조항이 그 판단 기준이다 — 이 revision 의 closeout 은 그 별개 작업들의 산출을 검증-신호 *입력으로 소비*할 뿐, 그 작업들을 이 changeset 에 편입하지 않는다(순환 없음). 이 선언은 landing 커밋과 closeout 기록 양쪽에 기록한다(closeout-checklist 항목).

## Batch 정의

- **목적**: E1 의 not-authority marker 의 lifecycle 의미와 verified-authority 소비 경계를 명시하고, promoted-but-not-live domain 의 implementation 이 정규 배포-경로에 편입되는 것이 운용-검증(dogfood) 경로임을 명문화.
- **scope(다루는 것)**: E1 절의 해당 문장 뒤 명확화 추가 + **기존 implementation-authority 괄호의 authority-축 명시**(consumer 의 default 가 build on 하는 권위 — `live` = closeout-검증 / `sync-required` = 승인된 target-state 의 이원; runtime availability 와 분리 — 갈렸던 두 독해의 뿌리 구문을 직접 판별) — 요소: (a) not-authority marker = lifecycle 위치 서술·"검증된 authority 소비" 제약(배포-편입 금지 아님; 소비-금지의 실효 범위 = governance 판단 계층) (b) active surface 의 배포-경로 landing 허용 + 그것이 운용-검증 경로이고 그 phase 의 사용은 검증-입력(우회 차단: 배포 구현을 통한 소비가 authority 를 만들지 않음) (c) phase 가 live 와 공유하는 것 = runtime activation topology(governance 상태 아님) (d) 운용 중 결함 = 분류·수정할 failure signal(구현/spec-sync/lifecycle 중 무엇이든) (e) 배포 mechanics·환경은 자기 active surface 소유(이 rule 이 재배포 절차를 소유하지 않음) (f) permits·mandates nothing·승인 게이트 불변. **+ promotion checklist 의 prelive-소비 항목에 landing-비위반 명확화 반영**(form-bound: checklist-tested obligation) — 이 checklist 문구는 promotion-boundary 이벤트 시점의 오독 방지용이며, promotion 이후 별도 changeset 의 implementation landing 은 이 checklist 의 trigger 가 아니다(그 시점의 E1 경계 판단은 rule 본문과 그 changeset 의 리뷰 게이트가 커버한다). **+ Design open risk 3 의 backlog 추적 행 추가**(`docs-working-model_backlog.md` DWM-B-14). **(다루지 않는 것)**: Spec identity·Incubation tier 의 기존 "(E1)" pointer 문장들(무변) · 타 조문 · 개별 domain 문서.
- **package-form 보고(form-bound 의무 — closeout 절)**: promotion checklist = **updated** / Design·Plan·Spec templates = checked — no change required(역할 구조 무변) / Design·Plan·Spec·Work Packet checklists = checked — no change required(각 checklist 의 검사 축은 이 명확화와 무관) / closeout checklist = checked — no change required(governing-version·form-bound 항목이 이 케이스를 이미 커버) / check script·tests = checked — no change required(E1 기계 검사는 candidate-folder discovery 구조 검사로 이 의미 경계를 다루지 않음 — 의미 경계는 checklist/review 소관). 이 판단들을 landing 커밋 메시지에 기록하고, 지연된 closeout report 에서 listed-surface 결과를 재현한다.
- **hard boundary(불가침)**: E1 의 기존 artifact-측 제약 문장 · two-layer discovery 구조 · closeout gate · 모든 승인 게이트 문면 · "no `.claude/*` surface" 는 루트 지시 파일 소유(rule 이 재정의하지 않고 사실로 참조만).
- **validation expectation**: 명확화가 "허용·경로" 서술이지 "배포 의무"가 아님이 문면에서 성립 / 기존 artifact not-authority 불변식의 *의미* 보존(implementation-authority 괄호는 authority-축 이원 명시로 수정 — 문면 무변 아님; `sync-required` 의 "재검증 대기" 정의와 모순 없음) / docs-working-model-check PASS(E1 검사는 구조 검사라 비촉발 예상) / full Pester 무회귀 / `.md` 인코딩 규약.
- **review focus**: E1 기존 제약의 비약화 · 과교정(배포 의무화 독해) 방지 · 기존 조문과의 모순 0 · 이 명확화가 갈렸던 두 독해를 실제로 판별하는가.
- **Work Packet**: 불요 — 이 revision 의 회차성 분석은 git history 가 이미 보유하며, 새로 수집할 라인-레벨 분석이 없다.

## Open decision 의 close 지점

- Design open risk 1(과교정 방지) — 이 changeset 의 문안 + 게이트에서 닫음.
- Design open risk 2(실전 충분성) — **이 revision 의 지연된 closeout 에서 닫음**: 아래 retire 조건.
- Design open risk 3(배포된 prelive 의 소비자-가시 표시 부재 — 수용 리스크) — **이 changeset 에서 backlog 행 DWM-B-14 로 추적 등재하여 close**(수용 + 추적; reopen 조건은 그 행이 보유).

## Retire(closeout) 조건 — 명시 지연

이 revision 의 promoted-lifecycle closeout(본 Plan·Design 의 retire)은 rule landing 시점에 수행하지 **않는다**. 조건: **B(blind-advisory)·O(subagent-work-orchestration) 실사용 검증 후 + 사용자 명시 지시** — 구체 신호(리뷰 결론을 조건화하지 않는 중립 이벤트): ① B Implementation changeset 의 재리뷰와 ② O 의 promote·Implementation 리뷰 게이트가 각각 **종결**되고(verdict 내용을 이 조건은 지정하지 않는다), 그 과정에서 제기된 E1-관련 finding 이 있으면 각각 evidence 재구성과 명시 처분을 거친 상태 — 처분 = 수정, 또는 blocker 가 아님을 evidence 로 재분류한 뒤의 수용(true blocker 를 수용으로 낮추지 않는다). 판정 = operator 보고 + 사용자 판단. (검증의 실 소비자가 규칙을 밟아본 뒤에 닫는다 — 선행 revision 이 그 전에 닫힌 재발 방지.) **role-slot 점유 명시**: 이 Plan 이 남아 있는 동안 같은 role-slot 의 새 docs-working-model revision 은 *State migration* 절에 따라 이 revision 의 disposition 이 선행돼야 한다 — 수용된 점유다. 조기 closeout 이 필요해지면 게이트 면제가 아니라 **이 retire 조건의 개정(사용자 승인) 후 closeout** 경로를 밟는다.

## Stage rewind 조건

- 이 Plan 이 Design 의 semantic target·non-goals 위반 → stop · Design 재설계 · Plan 재시작.
- terminal rule 문안이 이 Plan 의 scope/hard boundary 초과(예: pilot-gate 도입·artifact-제약 약화·타 조문 확장) → stop · 재-plan.
- 구현(rule 편집)이 boundary 초과 → stop · 사용자 확인.
