# docs-working-model Work Packet — NC-05 finite inventory

> **상태:** non-authoritative·non-live 조사 문서. 승인 대상도 terminal rule도 아니다.
> **범위:** `rules/docs-working-model/docs-working-model.md`의 강한 의미 조항과 지정된 기계 검사.
> **금지:** 실행 기록·review 결과·readiness 판정·최종 normative 문면을 이 문서에 두지 않는다.

## 1. 고정 판정 기준

### 1.1 규칙 지위 불변식

이번 inventory는 다음 세 기준을 먼저 고정하고 현행 DWM을 그 아래에서 심사한다.

1. **상호 무충돌 원자:** 다른 정당한 owner의 독립성을 침범하지 않고 단독으로 설명·적용할 수 있다.
2. **파생 충돌 해소 기준:** 파생 규범이 충돌할 때 어떤 owner·evidence·appeal 경로로 해소할지 제시한다.
3. **정규 개정·흡수 채널:** 유지할 수 없는 규칙을 정규 lifecycle에서 좁히고·강등하고·이관하고·제거할 수 있다.

형식·전칭이라는 이유만으로 원자 지위를 주지 않는다. 위 세 기준으로 소급되지 않는 강한 파생은 강등 후보이다.

### 1.2 처분 vocabulary

| 처분 | 의미 |
|---|---|
| `retain` | 현행 의미 강도를 유지하되 압축·명료화는 가능 |
| `narrow` | 실제 judge·evidence·counterexample에 맞게 적용 범위나 blocker 강도를 축소 |
| `demote` | 유용한 안내·review aid로 남기되 독립 hard blocker 지위 제거 |
| `remove` | 종료된 이행 예외·중복·오해 유발 문면을 active rule에서 삭제하고 git history로 보존 |
| `transfer` | 의미를 실제 active owner로 옮기고 DWM에는 필요한 interface pointer만 남김 |

### 1.3 기계 검사 호칭

| 호칭 | 판정 기준 |
|---|---|
| `deterministic diagnostic` | 명시 호출 시 같은 입력에서 결정적으로 PASS/FAIL하지만, lifecycle transition이 반드시 호출하고 실패를 차단하도록 배선되지 않음 |
| `lifecycle hard gate` | 명시된 lifecycle transition이 반드시 호출하며, 실패가 그 transition을 기계적으로 차단함 |

“binding rule을 일부 검사한다”와 “lifecycle hard gate로 배선됐다”는 다른 주장이다.

## 2. 강한 의미 조항 inventory

표의 `심사`는 제안일 뿐 승인된 처분이 아니다. `판정/근거/반증/회색`은 유지·축소 시 사용할 비례 판단축이고, 이관·제거 시에는 owner 또는 폐기 이유를 적는다.

### 2.1 적용·artifact·배치

| ID | 현재 anchor | 강한 의미 | 강도 근거 | 제안 | 판정/근거/반증/회색 또는 owner·폐기 이유 |
|---|---|---|---|---|---|
| DWM-S01 | 3, 7–11 | docs/lifecycle/temp/backlog 작업 전 DWM을 읽고 적용 | 모든 관련 변경의 선행 의무 | `narrow` | 실제 normative 의미·placement·closeout 변경이면 적용. 단순 열람·비권위 보고에는 적용하지 않음. 경계가 불명확하면 어떤 DWM-owned 의미가 변하는지 제시해 appeal |
| DWM-S02 | 13–21 | 문서 artifact는 정확히 다섯 class 중 하나이며 역할 혼합은 결함 | 전 문서에 배타 분류 | `narrow` | class는 owner 분리를 위한 기본 taxonomy로 유지하되, 복합 파일을 자동 결함으로 보지 않고 서로 다른 authority를 함께 주장할 때만 blocker. 단순 pointer/요약은 반증 |
| DWM-S03 | 17–21 | Planning만 Spec live, temp는 삭제, report는 log, active behavior는 active surface, backlog는 비권위 | class별 권위·수명주기 | `retain` | 파일이 실제로 다른 class의 권위나 수명을 주장하는지가 judge. 이름만 다른 것은 반증, 역할이 겹치면 owner별 분리 |
| DWM-S04 | 25–41 | docs end-state, per-domain migration, end-state 우선, legacy no-grow, orientation single home | 미래 배치 방향을 현재 강제 | `narrow` | end-state·per-domain 실행·orientation single home은 유지. “legacy no-grow”는 실제 retirement 대상에 새 권위가 추가될 때만 적용; 필수 오류 정정·현재 사용자 경로 유지는 허용 |
| DWM-S05 | 43 | 모든 fact는 single authoritative home, 나머지는 pointer | 전면 단일 홈 | `narrow` | 동일 규범·결정의 독립 authoritative copy가 둘이면 결함. interface 요약·예시·local acceptance criterion은 반증. 변경 시 함께 바뀌어야만 같은 fact인지 판단 |
| DWM-S06 | 45 | committed doc의 local/runtime durable pointer 금지 | 모든 committed doc에 절대 금지 | `retain` | 해소 대상이 tracked file/git history인지가 결정 가능 judge. path class 설명은 반증. 현재값이 필요하면 active owner에 직접 쓰고 외부 path는 evidence로만 둠 |

### 2.2 Design/Plan/Spec/Work Packet

| ID | 현재 anchor | 강한 의미 | 강도 근거 | 제안 | 판정/근거/반증/회색 또는 owner·폐기 이유 |
|---|---|---|---|---|---|
| DWM-S07 | 47–56 | normative change는 Design→Plan→Spec/rule→implementation→closeout 고정 lifecycle | ad-hoc 저작 금지 | `narrow` | durable normative meaning을 새로 만들거나 바꾸면 적용. owner-local 의미 보존 정정은 proportionality 경로. rule은 Spec 대신 terminal rule |
| DWM-S08 | 58 | detail은 종류별 Design/Plan/Spec·rule/WP/log/backlog/glossary/active surface로 흐름 | altitude 위반을 결함화 | `narrow` | 문서가 하위 내용을 승인 근거로 선점하거나 상위 결정을 하위로 숨기면 blocker. 식별에 필요한 대표 예·짧은 근거는 반증. 과도성은 의미 중복과 승인 우회를 evidence로 제시 |
| DWM-S09 | 60 | 문법이 아니라 실제 승인 owner 변경·자가승인을 결함으로 판정 | 승인 소유 판정 기준 | `retain` | 새 결정·기결 변경·자가승인 여부가 judge. 명시적 기결 추적은 반증 |
| DWM-S10 | 62 | Design은 의미 목표·trade-off·owner·non-goal만, 하위 상세·최종 문면 금지 | Design content hard boundary | `narrow` | Plan의 승인 선택지를 선결하거나 WP inventory를 복제하면 blocker. 선택을 이해시키는 decision-grade identifier/경계 예시는 허용 |
| DWM-S11 | 63 | Plan은 승인 대상 batch·scope·boundary·validation·review·WP 선언만 | Plan content hard boundary | `narrow` | 승인 선택과 변경 경계가 judge. 짧은 의존 설명은 허용; 조사 결과나 실행 로그가 승인 근거를 대체할 때만 blocker |
| DWM-S12 | 64–65 | Spec은 target-state, implementation은 final Spec 기준, closeout 1:1 | 구현 권위 경로 | `retain` | externally observable behavior/owner boundary가 final Spec/rule에 있는지가 judge. WP는 참고만 가능 |
| DWM-S13 | 67–73 | Spec의 prelive/sync-required/live 상태, 8개 의미 영역, 금지 content | 닫힌 section/marker·content gate | `narrow` | **확정:** lifecycle state·durable target-state·정확히 하나의 marker는 의미 invariant로 유지하고, 정확히 8개 heading은 form diagnostic으로 낮춘다 |
| DWM-S14 | 75–81 | WP는 round-scoped 비권위 임시 artifact, 실행·review 결과 금지, closeout 삭제 | WP 역할·수명주기 | `retain` | round 종료 후 live여야 하는 의미가 WP에만 남으면 결함. 조사·edge case·제안은 반증 |

### 2.3 Incubation·rule_docs·candidate

| ID | 현재 anchor | 강한 의미 | 강도 근거 | 제안 | 판정/근거/반증/회색 또는 owner·폐기 이유 |
|---|---|---|---|---|---|
| DWM-S15 | 85–87 | candidate admission에 문제·shape·owner·review-date·discard criteria 전부 없으면 out-of-repo | 하나라도 없으면 입장 금지 | `narrow` | 유일 필수 작성 요소는 candidate 도메인 정체성이다. 문제·shape·owner·review-date·discard criteria는 선택 권장으로 바꾼다. hard 판단은 기존 domain과의 완전 중복뿐이고, 부분 중복은 agent가 사용자에게 확인하는 soft warning이다 |
| DWM-S16 | 88 | candidate는 한 `_incubation`, non-authoritative, 별도 D/P/S 없음, promotion 때 Design 진입 | candidate 단일 홈·형태/권위 분리 | `retain` | `_incubation`은 후보 등록 의도만 가진 비권위 단일 홈이고 Design/Plan/Spec 권위를 갖지 않는다. 강제 header·template은 이 의미의 구성요소가 아니다 |
| DWM-S17 | 89–96 | `rule_docs/<id>`는 rule 1:1 planning home, 세 상태, backlog overlay, temp 삭제, 기존 rule folder 지속 | 폴더 상태 전칭·수명주기 | `narrow` | candidate의 in-repo 단일 홈과 promotion 시 기존 rule planning home으로의 전환만 유지한다. snapshot 물리 조합은 S18/S46 소유이므로 이 재처분에서 새 author ceremony를 만들지 않는다 |
| DWM-S18 | 97 | rule_docs 허용 파일/폴더·orphan·candidate backlog를 닫힌 집합으로 제한 | checker-backed purity | `narrow` | **확정:** 혼합 owner·archive 회피·orphan authority만 blocker로 두고 닫힌 파일 집합은 기본값+diagnostic으로 좁힌다. 인큐베이션은 `_incubation` 단일 홈·E1–E3·promotion swap을 계속 만족한다 |
| DWM-S19 | 98 | candidate anchor→formalize→pilot→promote/discard/continue, review-date·E4 흡수·defer·sweep | 한 문단에 life-event 전부 hard | `narrow` | 생명주기를 자유 기록→자유 메모→Design 승격의 prelive commit/push 시 closeout으로 단순화한다. promotion changeset의 `_incubation`→`_design` swap과 필요한 내용 흡수만 유지하며, review-date·formalize·pilot·정기 처분 ceremony는 의무가 아니다 |
| DWM-S20 | 99, 101–104 | terminology는 네 trigger에만 glossary adopt/reject/remove, candidate-local 이름은 local | glossary mutation trigger | `narrow` | incubation 중 candidate-local 이름·분류는 메모장 소유이며 작성 자체로 glossary/lifecycle을 트리거하지 않는다. Design 착수 뒤 project-wide 의미가 실제 도입될 때 glossary owner의 일반 trigger를 적용한다 |
| DWM-S21 | 100 | distributed rule landing 시 universal-core/project-residue split·rehoming | 타 tier 정합을 same changeset 강제 | `narrow` | distributed admission 기준은 `snippets/rules/README.md`를 가리키되, lifecycle이 운반한 project residue를 올바른 owner로 흡수하거나 명시 폐기해 closeout 삭제 때 조용히 잃지 않는 의무는 DWM에 남긴다 |
| DWM-S22 | 105 | candidate form은 canonical authority가 아니며 E1–E5 즉시 적용 | core invariant + 묶음 hard gate | `narrow` | form/authority 분리와 E1–E3 freedom-wall은 유지한다. 강제 form은 없고 E4는 최소 흡수로 좁히며 종료된 E5는 즉시-binding 묶음에서 제거한다 |
| DWM-S23 | 106 | E1 discovery/authority 이층, prelive dogfood 허용·authority 불부여 | governance·runtime 전면 경계 | `retain` | candidate folder·등록 의도는 canonical discovery나 구현 authority가 아니다. prelive 존재·dogfood·배포는 verified authority를 만들지 않으며, distribution mechanics는 해당 active owner가 계속 소유한다 |
| DWM-S24 | 107 | E2 canonical surface의 candidate doc durable reference 금지, absorbed summary만 허용 | 모든 canonical ref hard fail | `retain` | canonical surface는 `_incubation` 문서나 그 미흡수 semantics를 durable input으로 소비하지 않는다. name identity와 독립적으로 재검증 가능한 absorbed summary는 candidate authority 소비가 아니다 |
| DWM-S25 | 108 | E3 incubation artifact의 canonical default/input 금지, sibling 금지, rename lineage atomicity | 전면 default/input + same-change swap | `retain` | incubation 동안 canonical default/input·Design/Plan/Spec sibling을 만들지 않는다. Design 승격 changeset이 `_incubation` 제거와 `_design` 생성을 함께 수행하는 것이 closeout 종점이다 |
| DWM-S26 | 109 | E4 흡수 시 결론·대안·판단변경 evidence type·scope·failure·negative evidence 전부 보존 | 닫힌 흡수 필드 | `narrow` | Design이 실제로 이어받는 candidate 정체성과 current-bearing 아이디어만 의미 보존해 흡수한다. 여섯 필드는 닫힌 의무가 아니고 해당 없음은 생략/N/A 가능하며, 자유 메모·raw log·폐기된 생각을 모두 운반하지 않는다 |
| DWM-S27 | 110 | E5 incubation 도입·일반화의 일회성 bootstrap | 끝난 changeset 전용 예외 | `remove` | 미래 work를 판정하지 않는 종료 이력. git history가 owner |
| DWM-S28 | 111 | promoted artifact의 incubating sibling name mention 허용 조건·life-event sweep | 긴 조건 전부 reviewer blocker 가능 | `narrow` | name-only mention은 candidate임을 속이지 않고 권위·semantics를 소비하지 않으면 허용한다. 별도 marker·registry·전수 ceremony는 만들지 않고, 실제 stale authority claim이 생길 때만 해당 reference를 고친다 |
| DWM-S29 | 112 | incubation에는 기본적으로 DWM 모든 조항 적용, 열거된 것만 완화 | default-strict 전칭 | `remove` | bare removal 뒤 positive 경계를 둔다: incubation은 임시·자율 메모이며 positive authority는 후보 등록 의도 하나뿐이다. freedom-wall과 commit safety floor만 적용하고, 정규 DWM lifecycle/review는 Design 착수부터 적용한다 |
| DWM-S30 | 113–116 | seed/log/tracked 분리, WP coexistence, absorption commit scrutiny, no round cap | candidate 운영 경계 | `narrow` | seed/log/tracked 분리와 round cap 부재는 유지하되 별도 WP·absorption ceremony를 요구하지 않는다. 메모 작성은 lifecycle trigger가 아니며, commit은 public-safe/no-secrets·사용자 승인과 경량 중복 확인만 따른다 |

#### 인큐베이션 positive 최소 계약

이 계약은 S15–S30 재처분의 공통 결과 제안이며 S18/S46의 물리 구조 처분을 승인하지 않는다.

1. **정체성·권위:** `_incubation`은 candidate 도메인의 정체성만 필수로 적는 자유 메모장이다. positive authority는 “이 도메인을 후보로 등록할 의도”뿐이고, 다른 canonical surface에 의미·구현 권위를 부여하지 않는다.
2. **중복 검사:** 작성/논의 시 기존 domain·rule 목록을 in-session으로 가볍게 대조하고 commit 직전 다시 훑는다. 완전 중복은 등록을 막고, 부분 중복은 겹치는 owner를 알려 사용자가 그대로 둘지 확인한다. 스크립트·registry·별도 review ceremony는 만들지 않는다.
3. **freedom-wall:** E1–E3가 candidate의 canonical discovery·durable input·default 소비와 incubation 중 canonical sibling을 막는다. 이 벽은 저자에게 추가 form을 요구하지 않는다.
4. **생명주기:** 자유 기록으로 시작해 자유롭게 수정한다. Design 승격이 commit/push되어 prelive에 들어가는 changeset에서 필요한 아이디어를 `_design`에 흡수하고 `_incubation`을 제거한다. 정규 lifecycle은 Design 착수부터 적용한다.
5. **리뷰 carve-out 제안:** incubation 생명주기 동안 `_incubation` 자체에는 canonical·Blind를 포함한 review gate를 적용하지 않는다. public-safe/no-secrets 의무와 사용자 commit 승인은 계속 적용한다. 적용 가능한 결정적 진단은 실행할 수 있지만 secret 부재를 증명하는 scanner는 없으므로 그 진단을 safety-floor의 기계적 보증으로 과장하지 않는다. 이 carve-out의 terminal DWM owner는 S53/L223이므로 이번 S15–S30 재처분에서는 요구사항만 기록하고 S53 처분은 변경하지 않는다.
6. **서식 없음:** template·필수 header·고정 section이 없다. 문제·shape·owner·review-date·discard criteria는 유용하면 쓰는 권장 메모이지 admission blocker가 아니다.

### 2.4 Backlog·동기화·proportionality·closeout

| ID | 현재 anchor | 강한 의미 | 강도 근거 | 제안 | 판정/근거/반증/회색 또는 owner·폐기 이유 |
|---|---|---|---|---|---|
| DWM-S31 | 118–125 | domain/rule당 backlog 하나, one-line+reopen, closed 삭제, no authority/cap, monotonic next ID, 지속 | queue 형식·수명주기 | `narrow` | **확정:** 비권위·single home·reopen condition·ID 비재사용은 유지하고 one-line은 default로 낮춘다. 실제 결정/incident ledger가 섞일 때만 blocker다 |
| DWM-S32 | 126 | rule backlog 최초 도입 changeset 일회성 bootstrap | 끝난 changeset 전용 예외 | `remove` | 미래 work를 판정하지 않는 종료 이력. git history가 owner |
| DWM-S33 | 128–134 | Spec↔implementation 1:1은 normative sentence/observable behavior·owner boundary, reconstructibility | full sync 기준 | `narrow` | 문장 단위 literal 대응이 아니라 behavior/owner 의미 대응으로 명확화. internal detail은 반증. 검증 불가능한 “완전 재구축”은 review aid로 강등 |
| DWM-S34 | 136–138 | live Spec은 in-place update 후 sync-required, 신규는 prelive, closeout live | state transition | `retain` | 기존 live 여부와 closeout 1:1 여부가 결정 가능 judge |
| DWM-S35 | 140–144 | normative meaning 변화는 full lifecycle, meaning-preserving은 direct | lifecycle invocation 기준 | `retain` | allow/forbid·behavior·owner·validation expectation 변화가 judge. typo/pointer/표현 명료화는 반증 |
| DWM-S36 | 146 | direct edit는 meaning-preserving 선언, editor-reviewer disagreement/doubt면 lifecycle | 의심 자체가 hard escalation | `narrow` | direct edit가 meaning-preserving이라고 밝히는 의무와 **normative 의미에 관한 unresolved doubt면 lifecycle로 올리는 보수 기본값**을 유지한다. 순수 style 선호·표현 취향의 이견은 이 doubt가 아니며, 의미 불확실성을 “근거가 부족하다”는 이유로 direct edit에 남기지 않는다 |
| DWM-S37 | 148–153 | closeout은 Level 1·2 모든 listed surface 무조건 inspect/report, 누락 gate fail | 전 표면 ritual hard gate | `retain` | **확정:** listed surface의 inspect/report unconditional을 anti-omission 기본값으로 유지한다 |
| DWM-S38 | 153 | open blocker는 해결, future work는 backlog | landing 판단 | `retain` | 현재 correctness에 필요한 질문인지가 judge. 구현 없이도 landing이 정합하면 reopen condition과 함께 defer |
| DWM-S39 | 153 | form-bound statement 변경 시 forms/checker/tests 모두 same changeset sync | 닫힌 열거의 transitive hard gate | `narrow` | 해당 form/check가 그 문장을 실제 embody/enforce하는 직접 dependency일 때만 같은 changeset. 키워드 유사성은 반증; 미확실하면 call/field correspondence 제시 |
| DWM-S40 | 155–164 | closeout 1:1·current meaning 흡수·inbound sweep·D/P/WP 삭제 | lifecycle terminal 조건 | `retain` | live meaning 잔존·stale inbound·임시 artifact 미처분이 judge. git history 보존은 반증 |

### 2.5 Rewind·migration·self-amendment·cross-domain·forms

| ID | 현재 anchor | 강한 의미 | 강도 근거 | 제안 | 판정/근거/반증/회색 또는 owner·폐기 이유 |
|---|---|---|---|---|---|
| DWM-S41 | 166–170 | Plan→Design, Spec→Plan 위반은 rewind; implementation 초과는 stop/user | 단계 위반 처리 | `retain` | 하위 산출물이 승인된 상위 의미를 바꾸는지가 judge. 상세화는 반증 |
| DWM-S42 | 172–175 | 같은 role-slot prior artifact 처분 전 새 revision 금지, carryover 비권위 | revision seriality | `narrow` | 실제 동일 owner·동일 role-slot에서 두 current authority가 경쟁할 때 적용. 독립 parallel revision은 반증 |
| DWM-S43 | 176 | promoted-but-not-live withdrawal은 명시 changeset·전 artifact 처분·incubation 복원·sweep | de-promotion full procedure | `narrow` | unrecorded authority rollback 금지와 live 이후 normal repeal은 유지. 모든 mention을 무차별 sweep하지 않고 실제 status/reference가 stale해지는 표면만 |
| DWM-S44 | 178–182 | 새 governance mechanism은 introducing changeset에 소급 안 됨, pre-version이 closeout까지 지배 | self-reference 해소 기준 | `retain` | post-rule이 자기 도입을 소급 심사하는 순환이 있는지가 judge. 단순 wording edit는 반증 |
| DWM-S45 | 183–185 | bootstrap instance 열거·terminology removal carve-out·E1–E5 immediate-binding 해설 | 종료 역사 + 현 규범 혼합 | `narrow` | line 183의 종료 instance와 특정 terminology removal carve-out은 제거해 git history로 보낸다. line 185의 살아있는 원리—governance self-revision 중에도 pre-amendment structural check가 적용됨—는 S44 또는 closeout checklist에 유지한다 |
| DWM-S46 | 187–191 | stable role filenames, subfolder/topic proliferation 금지, auxiliary는 explicit lifecycle, package form 이름 | 물리 형식 hard boundary | `narrow` | **확정:** 같은 owner의 canonical role 분산·subfolder lifecycle 회피만 blocker로 두고 닫힌 role 집합은 기본값으로 낮춘다. 인큐베이션의 `_incubation` 단일 파일·promotion swap을 깨거나 별도 template/header를 요구하면 안 된다 |
| DWM-S47 | 193–195 | human-facing prose 언어 owner는 root instructions | owner pointer | `transfer` | 언어 의미는 root `CLAUDE.md`/`AGENTS.md`가 소유. DWM에는 재정의하지 않는다는 짧은 pointer만 유지 |
| DWM-S48 | 197–200 | domain-local closure, top-down reference | 타 domain 의미 의존 금지·routing 방향 | `narrow` | 자체 의미를 이해하려면 foreign owner의 semantics를 읽어야 하는지가 judge. 안정 interface·owner name·얇은 pointer는 반증 |
| DWM-S49 | 202–206 | domain semantics reference 기본 금지, interface만 허용, 구현변경 test, candidate contrast blocker | cross-domain reviewer blocker | `narrow` | foreign owner의 normative behavior를 로컬 정의처럼 소유하는지가 judge. interface/identity contrast/owner pointer는 반증. “구현 변경 시 문장 변경”은 보조 heuristic이고 반례가 있으면 owner-based appeal |
| DWM-S50 | 208–210 | committed current mirror 금지, on-demand authoritative synthesis | status mirror 금지 | `retain` | committed file이 현재 queue/summary의 authoritative copy가 되는지가 judge. 대화 briefing·runtime relay status는 반증 |
| DWM-S51 | 212–217 | 모든 산출물은 checklist 통과, checklist 의미 판정, approval boundary once | checklist 자체 hard gate | `demote` | **확정:** checklist는 누락 탐지·self-review aid로 두고 실제 underlying rule violation evidence가 있을 때만 blocker다. incubation review carve-out은 별도 적용한다 |
| DWM-S52 | 218 | rule body form-bound 변경은 같은 changeset sync, spec-template 8 section/3 marker machine check는 즉시 binding | form/check가 독립 hard gate | `narrow` | **확정:** 직접 dependency sync와 lifecycle marker 의미는 유지하고 정확히 8 heading은 호출 시 form diagnostic으로 정직화한다. “machine checked”는 lifecycle 배선이 아니라 명시 호출 범위만 뜻한다 |
| DWM-S53 | 220–223 | legacy application은 별도 batch+absorption+sweep+review; review verdict는 mutation 승인 아님 | scope/review/approval 경계 | `retain` | 실제 scope와 explicit approval이 judge. verdict는 evidence일 뿐 권한 아님 |
| DWM-S54 | 225–227 | DWM은 repo-only, distributed/adopter universal 아님 | tier boundary | `retain` | 설치 payload 포함 여부와 owner tier가 결정 가능 judge |

## 3. 유한성 coverage

다음 대조는 현행 heading과 inventory ID를 1:1로 연결한다. 행이 없는 heading은 없다.

| 현행 영역 | inventory |
|---|---|
| 적용, artifact class, end-state, single home, pointer | S01–S06 |
| lifecycle, altitude, approval, Design/Plan/Spec/WP | S07–S14 |
| incubation, rule_docs, candidate lifecycle, E1–E5 | S15–S30 |
| backlog, 1:1, live update, proportionality, closeout | S31–S40 |
| rewind, migration, self-amendment, filename/language | S41–S47 |
| domain-local, cross-domain, no mirror, forms, review, tier | S48–S54 |

복합 문단은 의미가 독립된 경우 별도 ID로 나눴고, 단순 package note·예시·설명 문장은 가장 가까운 ID의 근거로 흡수했다.

## 4. 기계 검사 배선 inventory

### 4.1 call-site 판정

- `scripts/docs-working-model-check.ps1`의 repo 외 호출자는 관련 Pester fixture와 문서상 수동 호출 pointer뿐이다. commit·promotion·closeout·review transition이 이 스크립트를 반드시 호출하는 구현은 없다.
- `scripts/verify-ps1.ps1`은 root instruction과 CONTRIBUTING에서 수동 validation으로 요구되고 install source marker로도 쓰이지만, commit/hook/closeout transition이 실행을 강제하지 않는다.
- 따라서 아래 대상 중 현재 `lifecycle hard gate`는 **0**이다. 각 검사는 호출되면 non-zero로 실패하는 binding subset일 수 있으나 배선 지위는 모두 `deterministic diagnostic`이다.

### 4.2 검사별 분류·정직화 제안

| 검사 | 구현 anchor | 실측 범위 | 현재 배선 | 분류 | 문면 정직화 제안 |
|---|---|---|---|---|---|
| Step F | `scripts/verify-ps1.ps1:69–140` | `tests/**/*.ps1`의 물리 한 줄 literal `& exe ... 2>&1`, 허용 3형 | verify를 명시 호출할 때만 실행; lifecycle 필수 호출 없음 | `deterministic diagnostic` | “verify 호출 시 hard-fail하는 제한적 lexical diagnostic; lifecycle hard gate 아님” 유지 |
| RULE_DOCS-PURITY | DWM checker `148–182, 290` | loose top-level·유효 state 부재 | checker 수동 호출·관련 Pester만 | `deterministic diagnostic` | rule의 “mechanically checked”를 “checker 명시 호출 시 진단”으로 변경 |
| RULE_DOCS-FILE | `183–215` | child subfolder·허용 집합 밖 파일 | 동일 | `deterministic diagnostic` | 허용 집합은 현 implementation convention이며 새 role lifecycle 통로를 막지 않는다고 명시 |
| RULE_DOCS-ORPHAN | `253–281` | idle folder에 terminal rule 없음 | 동일 | `deterministic diagnostic` | snapshot orphan 진단으로 한정; rename/delete 전체 procedure 증명 아님 |
| RULE_DOCS-CANDIDATE-BACKLOG | `231–251` | rule 없는 folder의 backlog | 동일 | `deterministic diagnostic` | existing-rule queue 구조 진단으로 한정 |
| E1 | `435–464` | candidate folder를 `docs/README.md`/`rules/README.md` discovery target으로 참조 | 동일 | `deterministic diagnostic` | semantic E1 전체가 아니라 두 README의 path/discovery subset만 검사한다고 전면 명시 |
| E2 | `294–402` | 정해진 canonical `.md` set의 발견된 candidate incubation path common forms | 동일 | `deterministic diagnostic` | globs·미탐 형태·name mention 제외를 짧게 공개; 전체 durable-reference proof로 부르지 않음 |
| E3 | `322–331` | 같은 folder의 incubation+design/plan/spec sibling | 동일 | `deterministic diagnostic` | lineage/rename-evasion은 manual; same-folder snapshot subset이라고 명시 |
| EN-2 | `470–569` | promoted domain Spec의 Lifecycle state heading 1개·bold marker 1개 | 동일 | `deterministic diagnostic` | produced Spec marker diagnostic. lifecycle transition 자체를 차단하지 않음 |
| DOCS-PURITY | `678–737` | promoted docs domain의 subfolder·허용 파일 집합 | 동일 | `deterministic diagnostic` | 물리 구조 subset. auxiliary role 승인 여부는 semantic review 소유 |
| BACKLOG-NEXTID | `744–847` | domain/rule backlog의 per-prefix floor·row max | 동일 | `deterministic diagnostic` | 삭제 gap 재사용·미래 intent는 미검사인 floor diagnostic으로 명시 |
| SPEC-TEMPLATE-SCHEMA | `575–674` | 고정 template path의 8 headings·3 markers | 동일 | `deterministic diagnostic` | marker/meaning 보조 검사로 호칭; 8 heading 형식 자체를 독립 lifecycle blocker로 쓰지 않음 |

`SIBLING-MENTION`은 exit code에 영향을 주지 않는 advisory INFO inventory이며, 주어진 두 호칭의 실패 검사 집합에 포함되지 않는다.

## 5. 처분 간 직접 의존

| 제안 묶음 | 직접 영향 후보 |
|---|---|
| S13/S52의 8-section 형식 강도 축소 | Spec template/checklist, `SPEC-TEMPLATE-SCHEMA`, 관련 tests |
| S17/S18/S46의 physical role 집합 축소 | DWM checker `RULE_DOCS-*`/`DOCS-PURITY`, 관련 tests |
| S23–S25의 E1–E3 범위 축소 | checker의 scope 문면과 관련 tests; semantic 미기계화 부분은 새 scanner 없이 manual |
| S31의 backlog 형식 축소 | `BACKLOG-NEXTID`는 ID floor invariant만 유지 |
| S37/S39/S51의 closeout/checklist 권위 축소 | closeout·artifact checklists의 blocker 표현 |
| S44 유지, S27/S32 제거, S45 narrow-split | 종료 instance와 특정 carve-out은 제거하되 S45 line 185의 pre-amendment structural-check 원리는 S44 또는 closeout checklist에 보존 |
| S15–S30 인큐베이션 재처분 | terminal DWM의 incubation clause와 S53 review carve-out. S18/S46 physical role 처분은 이 묶음에서 변경하지 않음 |

이 표는 수정 승인이 아니라, 처분이 승인될 경우 같은 changeset에서 확인할 직접 dependency 후보이다.

### Terminal 저작 기록

- 인큐베이션 safety floor는 public-safe/no-secrets 의무와 사용자 commit 승인이 소유한다. 현존 deterministic diagnostics는 각자 구현 범위만 증명하며 secret scanner가 있는 것처럼 쓰지 않는다.
- S53의 일반 review 문면과 확정된 incubation review carve-out은 terminal DWM을 쓰는 같은 changeset에서 함께 정합화한다. 둘 중 하나를 먼저 독립 landing해 모순 상태를 만들지 않는다.

## 6. 처분 확정 상태

- ① 인큐베이션 S15–S30은 LOCK 상태다.
- ② correction 3과 사용자 재정 5축은 모두 확정됐다.
- 최종 분포는 `retain 19 / narrow 30 / demote 1 / remove 3 / transfer 1`이다.
- 이 inventory에서 남은 open disposition은 없다. terminal 저작·직접 implementation은 별도 gate다.

## 7. 이번 문서의 흡수·retire 좌표

- 승인된 방향·trade-off는 terminal DWM rule에 흡수한다.
- 승인된 physical/check 의미는 직접 forms/checker/tests에 흡수한다.
- 이번에 착수하지 않을 독립 future work만 `docs-working-model_backlog.md`에 한 줄+reopen condition으로 이관한다.
- implementation closeout에서 이 Work Packet은 삭제하고 git history로 보존한다.
