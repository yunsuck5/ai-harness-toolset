# rule-conflict-and-revision-routing Plan

> Plan은 승인 대상인 의사결정만 담는 committed-temporary 문서다. terminal rule landing과 closeout에서 current-bearing 내용이 흡수된 뒤 삭제된다. 이 Plan은 mutation/commit/push/adoption/activation 승인이 아니다.

## Header

- 이 문서는 위 Design을 한 개의 self-contained global-distribution rule과 그 최소 통합 표면으로 landing하는 Plan이다.
- 이 체인이 끝나면 terminal rule, index, trigger routing, owner-local name boundary, 비례 검증이 한 corrected state를 이루고 planning docs는 retire된다.
- 이 문서는 최종 normative wording, 실행 명령 시퀀스, staging 절차, review/validation 결과 또는 adopter activation 절차가 아니다.

## Batch 순서와 의존

1. **Promotion transition entry:** 승인된 candidate promotion을 `_incubation.md` 삭제 + entry `_design.md` 작성으로 원자 전환한다. 같은 작업 흐름에서 Design을 기준으로 Plan과 round-scoped Work Packet을 작성한다. candidate id와 분류값은 owner-local 이름으로 유지하며 선등록하지 않는다. 이 묶음은 terminal behavior를 아직 만들지 않는다.
2. **G-1 terminal landing + promoted-lifecycle closeout:** transition 묶음이 approved commit으로 보존된 뒤, 새 distributed rule과 그 index/trigger/validation 통합을 한 changeset으로 완성한다. terminal rule landing과 같은 changeset에서 Design / Plan / Work Packet을 삭제하고 rule folder를 idle 상태로 남긴다.

두 단계는 docs-working lifecycle의 candidate closeout과 terminal landing 경계 때문에 구분한다. G-1 안에서는 rule 본문·routing·검증·closeout을 더 잘게 나누지 않는다. 각 changeset의 commit은 별도 사용자 gate이며, push/adoption/activation은 이 Plan 범위 밖의 별도 승인이다.

## Batch 정의

### Promotion transition entry

- **목적:** incubation의 current-bearing 판단을 E4 형태로 Design에 흡수하고 promoted-but-not-live rule lifecycle로 전환.
- **scope:** incubation 제거, Design / Plan / Work Packet 작성, candidate-status sibling mention sweep, candidate id와 `conflict-isolated` / `conflict-unit-blocking`의 owner-local 유지. 현재 실제 glossary trigger가 없음을 확인하고 provisional entry를 만들지 않는다.
- **hard boundary:** terminal rule·snippet trigger·distributed index는 아직 수정하지 않는다. incubation 원문을 보존용 shadow로 남기거나 canonical surface에서 참조하지 않는다.
- **validation expectation:** committed snapshot에 `_incubation.md`가 없고 Design / Plan / Work Packet만 active-lifecycle 역할로 존재한다. E4 항목과 7개 open-question 처분이 Design에 남고, glossary에는 provisional entry나 concrete runtime/scratch pointer가 없다. 이미 착수된 범위를 future work로 가장하는 backlog 문면이 남지 않는다.
- **review focus:** atomic swap, E4 누락, lifecycle altitude, owner-local name boundary, sibling mention 상태.
- **Work Packet:** 필요. 목적 = terminal landing의 exact surface/reference/edge-case 분석; 흡수 대상 = terminal rule·index/trigger·owner-local name boundary·validation과 operator evidence plan; retire 조건 = G-1에서 current-bearing 항목이 해당 owner surface와 검증에 반영되고 closeout gate가 성립할 때 삭제.

### G-1 terminal landing + closeout

- **목적:** Design의 conflict transport를 adopter-universal terminal rule로 landing하고 planning lifecycle을 닫는다.
- **scope:** genuine-conflict admission, binding-state preservation, dependency containment, same-tier conflict-set disclosure, inline report, compliant-alternative/revision handoff, owner-local fallback, non-goals를 terminal rule에 자족적으로 작성한다. distributed index와 두 vendor snippet의 같은 action-class trigger를 갱신하고, candidate-local 이름은 terminal rule의 owner-local vocabulary로 닫는다. 필요한 비례 검증과 rule-folder closeout을 같은 corrected state에 포함한다.
- **hard boundary:** 기존 세 distributed rule 본문, root `CLAUDE.md` / `AGENTS.md`, C/B/IU owner surface, global/user 설치본, activation surface는 수정하지 않는다. priority engine, exception authority, source-repo lifecycle, hidden state 또는 자동 실행을 terminal rule에 넣지 않는다.
- **validation expectation:** terminal rule이 vendor-neutral/public-safe/self-contained이고 distributed admission을 만족한다. trigger는 genuine conflict와 blocked-by-binding-rule revision request로 좁고 두 snippet이 대칭이다. isolated/unit-blocking 사례가 bypass와 over-stop을 함께 막고, owner-local 절차와 approval gates를 약화하지 않는다. planning docs 삭제 뒤 folder는 existing rule에 대응하는 idle `.gitkeep` 상태이며 backlog는 실제 future-work row가 있을 때만 생성된다.
- **review focus:** owner 독립성, completion laundering, post-hoc rescope, shared dependency 누락, same-tier recursion, user-approval-to-exception 오독, hidden-state 유입, source-repo residue, 과도한 trigger load.
- **Work Packet:** transition에서 작성한 하나의 Work Packet을 계속 사용한다. 새 packet 또는 별도 micro-batch를 만들지 않는다.

## Open decision의 close 지점

- genuine-conflict trigger의 최종 문면과 bootstrap action-class 설명은 G-1 terminal rule + snippet trigger에서 닫는다.
- `conflict-isolated` / `conflict-unit-blocking`의 최종 normative 경계는 G-1 terminal rule과 negative cases에서 닫는다.
- owner-local path가 자족하는 기준과 same-tier owner lifecycle 분리 문면은 G-1 terminal rule의 owner-interface 절에서 닫는다.
- candidate id와 두 분류값은 G-1 terminal rule에서 owner-local vocabulary로 닫는다. 그 시점에 실제 프로젝트 공용 용어 trigger가 새로 생긴 경우에만 glossary 채택/기각을 별도로 결정한다.
- static counterexample sufficiency와 promotion evidence threshold는 Design에서 닫혔으며 다시 live-pilot gate로 열지 않는다.
- live-use 안정성 부재는 accepted residual risk다. 현재 생성할 not-yet-started future-work가 아니므로 backlog로 이관하지 않는다.

## Validation / review gate

- Transition entry는 docs-working lifecycle structural check, E4/open-question/name-boundary/sibling sweep의 독립 감사, corrected-state canonical dual을 통과해야 한다.
- G-1은 docs-working lifecycle check, snippet/rules index·symmetry 관련 검사, PowerShell 검증과 전체 Pester, 정적 counterexample/false-positive 감사, corrected-state canonical dual을 통과해야 한다.
- 검토 뒤 reviewed artifact 또는 evidence가 바뀌면 영향 있는 review는 stale로 처리하고 해당 gate를 다시 수행한다.
- review verdict는 commit/push/adoption/activation 승인을 대신하지 않는다.

## Stage rewind 조건

- Plan이 Design의 one-rule-group, owner-local semantics, no-bypass 또는 no-hidden-state 경계를 위반하면 stop하고 Design부터 재설계한다.
- terminal wording이 generic arbitration·exception authority·owner schema 복제·source-repo dependency를 필요로 하면 G-1을 중단하고 promotion-withdrawal 또는 Design revision을 사용자에게 제시한다.
- 분류가 dependency facts로 재현되지 않거나 static negative cases에서 completion laundering/과도한 stop을 막지 못하면 terminal landing을 진행하지 않고 Plan 또는 Design으로 rewind한다.
- 구현 범위가 기존 owner rule 본문이나 C/B/IU surface로 확장돼야 한다면 G-1에 합치지 않고 해당 owner의 별도 lifecycle 여부를 사용자에게 돌린다.
