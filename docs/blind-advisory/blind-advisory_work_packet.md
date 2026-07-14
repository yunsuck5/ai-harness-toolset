# blind-advisory Work Packet

> 이번 corrective 회차의 조사·분류·대조 packet이다. 승인 대상 결정은 Plan, 목표 상태는 Spec, active behavior는 skill, 실행 결과는 `log/**`가 소유한다. 이 문서는 readiness·명령 시퀀스·review result·commit 절차를 담지 않으며 closeout에서 retire한다.

## Round purpose and boundary

- 목적: 기존 B 의미와 실제 transport/failure 경계 사이의 gap을 좁은 owner-local corrective로 분류한다.
- 입력 lens: current B Design/Plan/Spec/skill, active execution·git safety rules, Codex CLI의 분리된 final-message/diagnostic 채널, 독립 counter-framing과 failure-path 조사.
- 숨긴 것: 선행 verdict와 worker completion narrative는 correctness 근거로 사용하지 않는다.
- 범위: B의 7개 path만. 다른 advisory의 output 소비 개선, canonical result 구조 개선, instruction-trigger·shared-rule·glossary·activation·Brief/handoff는 별도 unit이다.

## Gap matrix

| Gap | 기존 상태 | corrective target | B가 넘지 않을 경계 |
|---|---|---|---|
| blindness | 모든 operator framing 제거라는 절대주장 | 열거된 conclusion/stance framing만 제거하고 remaining lens 공개 | framing-breaker 일반화 금지 |
| current-state 판단 | changed-state와 change-triggered obligation을 혼용 | current state와 제공된 standing obligation만 판단 | diff/history 추정 금지 |
| authority/evidence | authority criteria와 ordinary adjacent evidence 혼용, target-repo config 영향 잔존 | 둘을 분리하고 target-repo config/doc은 neutral cwd로 격리하며 자동 user-global authority는 공개 | target text/config의 authority 승격·ambient authority 은폐 금지 |
| finding | severity/confidence/assumption만 요구 | location·observation·expected/rationale까지 요구 | final blocker verdict 발급 금지 |
| trace | final message와 process transcript의 소비 경계가 불명확 | stdout/final-message만 결과, stderr trace는 별도 진단 | trace를 result로 보존·요약 금지 |
| large delivery | strict no-file 또는 타 domain transcript 선례 | 실제 inline capability 불능일 때만 B-owned raw result | artifact always-on·shared output mode 금지 |
| result shape | wrapper와 run metadata가 본문에 섞일 여지 | reviewer final message 외 section이 없는 최소 파일 | canonical-style 보고서·template 금지 |
| timeout | observation window 연장과 retry 혼동 | completion notification/JOIN, hard timeout no-retry | timeout 상승으로 pass 만들기 금지 |
| recovery | single-shot과 reviewer 재실행을 transport retry로 혼용 | carrier 전환 또는 proven pre-reasoning failure만 한 번 | 병행 retry·두 번째 reasoning run 금지 |
| target fidelity | deleted/rename/binary/stale bytes 분기 없음 | tombstone·rename identifier·binary fail-closed·in-memory binding | silent skip·sidecar ledger 금지 |
| supervised membership | JOIN 대상 집합 기록 없음 | launch 전 operator-visible expected set 기록 | untracked member·sidecar ledger 금지 |
| input encoding | PowerShell 5.1 text pipeline이 CJK stdin을 무음 변환 가능 | UTF-8 no-BOM direct byte-stream | exit 0을 completeness 근거로 오인 금지 |
| member disclosure | artifact carrier에서만 expected/joined 공개 | background/parallel/recovery면 carrier 공통 한 줄 note | inline recovery 은폐 금지 |
| cross-domain | 다른 advisory semantics를 대비 설명으로 재서술 | consultation name + B-owned no-invoke/no-consume만 | status/synthesis/output 의미 이식 금지 |

## Decision-to-surface mapping

| Decision | Design | Plan | Spec | Skill | Backlog / route |
|---|---:|---:|---:|---:|---:|
| bounded blindness + remaining lens | direction | approved | durable | operational | — |
| authority/payload separation | direction | approved | durable | operational | — |
| evidence-bearing finding + candidate blocking | absorbed | approved | durable | parser/prompt | — |
| stdout final-message only, stderr trace excluded | direction | approved | durable | adapter | — |
| inline-default raw-result fallback | direction | approved | durable | transport | — |
| minimal `result.md` with no wrapper/template | direction | approved | durable | transport | — |
| input binding + target edge cases | risk | approved | durable | collection | — |
| completion/JOIN/recovery | risk | approved | durable | adapter | — |
| future scope | pointer | boundary | — | — | single home |

## Failure-path matrix

| Failure observation | Plan/Spec contract point to verify | Counterexample if omitted |
|---|---|---|
| no changed paths | no-target failure branch | empty normal run |
| binary or NUL target | whole-run fail-closed + affected paths | skip, base64/hex generalization |
| unreadable or invalid-encoding target | mechanical `unavailable` branch | partial target set |
| deleted/rename needs prior state | `validation-evidence` vs `scope-curation` split | inferred history |
| bytes change after dispatch | acceptance-time stale binding rejection | recovery on new bytes |
| nonzero exit | abnormal-exit or narrower mechanical branch | parse partial stdout as result |
| stdout incomplete/truncated | no second reasoning; truncated failure | tail-only consumption |
| stdin bytes differ from bound payload | delivery failure before normal result | text-pipeline 변환을 성공으로 수용 |
| first-line status missing/ambiguous | parse failure without guessed status | assume `inconclusive` |
| required finding/scope/limitation fact missing | result-contract failure + missing fact | stderr trace로 결과 보충 |
| observation yield expires | same invocation notification/JOIN | timeout·retry로 해석 |
| hard timeout | terminate/JOIN and no retry | timeout increase or retry |
| inline channel cannot preserve full final message | preselected artifact or captured-message carrier transfer | summary, tail-only return |
| artifact create/verify fails | artifact failure facts only | partial artifact as normal result |

## Minimal-result analysis

- B가 보존할 정보는 reviewer의 final message다. model trace, workdir/model/session metadata, prompt echo, progress, token usage는 reviewer 판단이 아니므로 결과 본문이 아니다.
- inline과 artifact는 같은 완전한 reviewer message를 전달한다. 차이는 carrier뿐이며 artifact가 더 많은 section이나 설명을 요구하지 않는다. stdout emitter와 file writer의 terminal newline 차이 때문에 carrier 간 raw byte identity는 요구하지 않고, artifact의 bytes/hash만 실제 파일에 결박한다.
- first-line status와 finding facts는 reviewer message 내부 계약이다. artifact inline pointer에서 status를 다시 알리는 것은 소비자가 파일을 열기 전 run 상태를 식별하기 위한 최소 run fact이며, reviewer 내용을 이중 작성하는 근거가 아니다.
- 실패 진단은 원문 결과를 대체하지 않는다. 필요한 failure reason만 보고하고 전체 stderr trace를 result에 붙이지 않는다.

## Independent audit questions

- B가 실제로 조기 defect candidate를 찾는가, 아니면 canonical review의 축소 복제품인가?
- target·authority 선정 lens를 공개했는가, 아니면 “blind” 이름으로 숨겼는가?
- current-state-only evidence로 delta/history 주장을 만들었는가?
- `blocking`을 후보 severity가 아닌 최종 verdict처럼 소비할 여지가 있는가?
- unread target, binary, stale bytes, partial stdout를 정상 status로 세탁하는가?
- `result.md`를 만들기 위해 표지·요약·중복 section·template filling 비용을 새로 발생시키는가?
- stdout final message 대신 stderr/JSON event trace나 tail만 소비하는가?
- artifact fallback이 실제 capability 불능보다 편의·길이 추정·형식 선호에 의해 켜지는가?
- timeout/recovery가 기존 process를 남기거나 두 reasoning run을 병행시키는가?
- B의 해결을 위해 다른 owner semantics나 shared helper가 필요하다고 과장하는가?

## Absorption and retire

- identity와 방향 판단은 Design에 흡수한다.
- 승인 대상 결정은 Plan에 흡수한다.
- standing contract는 Spec에 흡수한다.
- 실행 mechanics는 skill에 흡수한다.
- 시작하지 않을 B future work는 backlog로 보낸다.
- 이 packet은 closeout에서 삭제한다.
