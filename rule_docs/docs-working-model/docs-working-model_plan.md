# docs-working-model — live rule lifecycle Plan

> 이 문서는 existing `docs-working-model` rule revision의 승인 대상 Plan이다. 이 체인은 rule add/change 보존, whole-rule retire/replacement source lifecycle, distributed source/runtime 분리, owner absorption closeout을 순서대로 닫는다. 실행 조사와 검증 결과는 이 문서에 축적하지 않으며, 이 Plan은 mutation/commit/push 승인이 아니고 closeout에서 삭제된다.

## Batch 순서와 의존

1. **Planning baseline**
   - DWM과 `rule-authority`가 각자 Design/Plan을 갖고 변경 경계와 governing version을 고정한다.
   - terminal rule, form, checker, test 의미는 아직 바꾸지 않는다.
2. **Rule source lifecycle**
   - 기존 add/change 경로의 entry·placement·closeout·resume interface를 명료화한다.
   - whole-rule retire/replacement의 absorb/dispose/terminal/resume를 DWM에 추가하고 `rule-authority`의 독립 handoff를 연결한다.
3. **Distributed projection**
   - repo-only와 distributed source projection을 구분하고 source/payload/activation 상태를 분리한다.
   - actual identity나 action route가 바뀌지 않으면 tier index·bootstrap·install implementation은 보존한다.
4. **Proof and closeout**
   - contract-only scenario로 여섯 항목 완료증거를 재구성한다.
   - direct dependency와 두-level closeout을 확인하고 planning artifacts를 삭제한다.

각 단계는 앞 단계의 owner 경계를 소비한다. 실제 source lifecycle이 닫히기 전에 distributed projection의 retire 결과를 주장하지 않는다.

## Batch 정의

### Planning baseline

- 목적: 두 rule owner의 독립 lifecycle과 승인 대상을 고정한다.
- scope: 각 owner의 Design/Plan.
- hard boundary: frozen 조사 자료나 다른 owner의 planning artifact를 authority로 승격하지 않는다.
- validation expectation: current DWM topology와 stable role을 deterministic checker로 확인한다.
- review focus: Design/Plan altitude, owner 독립성, non-goal, 미실증 위험.
- Work Packet: 만들지 않는다. line-level 구현 inventory가 작고 current owner·Git history·runtime observation으로 분리 가능하다.

### Rule source lifecycle

- 목적: add/change 경로를 보존하고 whole-rule absent state의 정상 terminal/resume를 추가한다.
- scope: DWM terminal rule, closeout checklist, DWM backlog, `rule-authority`의 얇은 handoff.
- hard boundary: rule-authority taxonomy, terminal rule별 claim, conflict containment 의미를 DWM에 복제하지 않는다.
- validation expectation: rule/backlog topology checker, affected DWM Pester, source diff의 owner-by-owner 1:1 대조.
- review focus: clause disposition과 terminal identity disposition 구분, retained meaning owner, replacement 병존 방지, drop/rescope/resume.
- Work Packet: 없음. durable 결정은 terminal rules에, 시점성 결과는 operator report에 둔다.

### Distributed projection

- 목적: terminal source, index/trigger, installed payload, activation 상태를 서로 다른 owner·증거로 유지한다.
- scope: DWM의 얇은 projection interface. 실제 target이 생긴 경우에만 해당 index/trigger surface.
- hard boundary: `INSTALL.md`의 self-contained 의미, manifest schema, status vocabulary를 DWM에 복제하지 않는다.
- validation expectation: existing recursive payload inventory와 snippet parity owner를 확인하고, 변경 없는 surface는 `checked — no change required`로 보고한다.
- review focus: source complete를 payload/operational complete로 확대하지 않는지, trigger 없는 active action rule을 일반 허용하지 않는지.
- Work Packet: 없음.

### Proof and closeout

- 목적: whole-rule replacement 있음/없음과 distributed source-only 잔여를 대표 scenario로 재구성하고 owner absorption을 닫는다.
- scope: terminal rules, direct form, owner backlog, planning artifact.
- hard boundary: dummy rule 또는 unapproved global activation으로 실사용 증거를 제조하지 않는다.
- validation expectation: affected 검사와 전체 suite, corrected-state self-review, two-level closeout.
- review focus: checker PASS의 semantic 과장, stale reference와 history citation 구분, actual execution 미실증 표기.
- Work Packet: 없음.

## Open decision의 close 지점

- whole-rule 성공 terminal의 최소 증거와 replacement 없는 drop/rescope 경계: Rule source lifecycle에서 닫는다.
- DWM closeout checklist가 terminal file 부재를 표현하는 방식: Rule source lifecycle에서 닫는다.
- `DWM-B-12` 중 rule 부분 흡수와 domain/identity 잔여 분할: Rule source lifecycle에서 닫는다.
- tier index·bootstrap·install surface 변경 필요성: Distributed projection에서 current owner와 직접 dependency로 결정한다.
- actual safe retire 대상 유무: Proof and closeout에서 재확인한다. 대상이 없으면 contract-only로 종결한다.

## Stage rewind 조건

- Plan이 Design의 owner 분리, 기존 add/change 보존, contract-only 허용을 바꾸면 Design으로 돌아간다.
- terminal rule 문면이 이 Plan의 hard boundary를 넘거나 domain/late-policy 의미를 흡수하면 Plan으로 돌아간다.
- 구현이 새 registry·scanner·global mutation 또는 다른 owner의 current slot 처분을 요구하면 해당 구현을 중단하고 별도 owner 결정으로 보낸다.
- 변경 전 DWM과 양립할 수 없는 구현은 우회하지 않고 affected unit을 보존한 뒤 governing owner를 재검토한다.
