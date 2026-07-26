# docs-working-model — live domain lifecycle Plan

> 이 문서는 existing DWM rule revision의 승인 대상 Plan이다. Domain add/change의 현재 채널을 보존하고 live retire·repeal·supersede의 source lifecycle과 glossary/runtime seam을 닫는다. 실행 기록은 담지 않으며 closeout에서 삭제된다.

## Batch 순서와 의존

1. **Add/change baseline**
   - promotion·prelive continuation·live normative revision·direct edit·implementation refactor의 current owner를 대조한다.
   - current synchronization과 Proportionality를 함께 적용해 existing 분류가 충분함을 확인하고 add/change source 문면은 변경하지 않는다.
2. **Live domain terminal**
   - exact identity/current state, 명시적 사용자 retire·repeal·supersede·rename/rehome 결정, successor 유무, retained meaning, source owner disposal, terminal/resume를 DWM에 추가한다.
   - Rename/rehome은 successor가 old identity를 대체하는 supersede의 identity transition으로 이번 contract에 포함하고 old/new Spec path·backlog identity·routing을 단방향으로 닫는다.
   - 처분 changeset이 닫히기 전까지 old live target-state/behavior owner는 binding이다. Successor가 있으면 absorption·replacement 준비 후 같은 changeset에서 전환하고, successor가 없어도 disposal·terminal 검증 전에는 old owner를 제거하지 않는다.
   - candidate discard와 `promotion-withdrawal`, B02 terminal-rule lifecycle을 그대로 보존한다.
3. **Owner seams**
   - glossary의 네 trigger와 domain-local 이름 경계를 read-only로 소비한다.
   - installed/global surface가 있으면 source closeout과 runtime follow-up을 분리한다.
4. **Proof and closeout**
   - replacement 있음/없음, rename/rehome, source-only/runtime 잔여 scenario를 contract-only로 재구성한다.
   - 직접 form과 backlog를 정렬하고 Design/Plan을 삭제한다.

## Batch 정의

### Add/change baseline

- 목적: 이미 작동하는 채널을 보존하고 surface 분류 사이에 겹침이 없음을 확인한다.
- scope: current DWM synchronization·Proportionality 문면의 read-only 대조.
- hard boundary: 역사적 절차 우회를 current compliance proof로 사용하거나 새 lifecycle state를 만들지 않는다.
- validation expectation: meaning-preserving Spec/rule prose edit는 marker 전이 없음; internal implementation refactor는 Spec/rule 변경 없음; observable behavior·owner·boundary·validation 의미 변경만 정규 lifecycle과 live Spec의 `sync-required` 전이를 요구한다는 세 반례를 current owner와 대조.
- review focus: implementation refactor와 Spec/rule direct edit의 상호 구분.
- Work Packet: 없음. line-level 구현 inventory가 작고 durable 결정은 terminal rule에 흡수된다.

### Live domain terminal

- 목적: live domain retire/repeal/supersede와 identity rename/rehome을 owner-local하게 닫는다.
- scope: DWM의 live-domain lifecycle 본문, closeout checklist, DWM backlog.
- hard boundary: 특정 실제 domain의 concrete implementation cleanup 열거, foreign semantics 복제, actual domain mutation 금지. Spec·behavior owner·routing·backlog identity·실제 stale reference라는 generic owner class는 계약에 포함한다.
- validation expectation: successor 있음/없음·rename/rehome·미준비 successor 반례와 two-level closeout 대조.
- review focus: old/new active owner 병존, premature removal, retained future work와 dependent work terminal.
- Work Packet: 없음.

### Owner seams

- 목적: domain-local change가 glossary revision으로 역류하지 않고 runtime/global 후속이 source 완료로 오인되지 않게 한다.
- scope: DWM의 얇은 interface와 existing glossary trigger read-only 대조.
- hard boundary: 새 glossary revision 착수, 새 term/state/scanner, global update/activation 금지.
- validation expectation: add/change/retire 대표 scenario를 glossary 네 trigger에 분류하고, trigger가 없을 때 `rules/terminology-glossary.md` changed surface 0을 확인한다.
- review focus: domain identity와 프로젝트 공용 term의 혼동, source/runtime 완료 확대.
- Work Packet: 없음.

### Proof and closeout

- 목적: contract-only 완료증거와 미실증 범위를 정직하게 남긴다.
- scope: DWM live-domain lifecycle 본문, direct closeout form, DWM backlog, planning artifacts.
- hard boundary: dummy domain, historical migration의 whole-domain proof 승격, checker PASS의 semantic 과장 금지.
- validation expectation: DWM checker, affected Pester, full Pester, corrected-state review, two-level closeout.
- review focus: DWM-B-12 흡수, source pilot과 deployed runtime pilot 독립 보존, planning residue.
- Work Packet: 없음.

## Open decision의 close 지점

- implementation refactor와 direct prose edit 경계는 Add/change baseline에서 닫는다.
- live retire/repeal/supersede의 최소 entry·absorption·disposal·terminal/resume는 Live domain terminal에서 닫는다.
- Rename/rehome은 supersede의 identity transition으로 이번에 닫는다. Old/new Spec path·backlog identity·routing은 동시에 active로 남지 않고 successor owner가 준비되지 않으면 old owner를 보존한다.
- DWM-B-12는 이번 contract에 전부 흡수해 닫는다. `DWM-B-20`에는 첫 실제 owner-local source retire/supersede pilot을, `DWM-B-21`에는 deployed/global runtime disposal의 첫 실제 pilot을 서로 독립된 row로 남긴다. B20은 exact live-domain 처분과 source mutation이 승인될 때, B21은 deployed surface가 있는 실제 domain 처분과 별도 global update/activation이 승인될 때만 연다.
- glossary·checker/test·actual domain surface 변경 필요성은 직접 dependency가 없으면 no-change로 닫는다.

## Governing version

- Pre-revision governing text는 `49ac6b6bf5808b04600f8253534c3c6f878f7c0e`의 `rules/docs-working-model/docs-working-model.md`다.
- 이 문면이 Design 시작부터 implementation closeout 전체를 지배하며, 새 DWM 문면은 이후 work부터 적용한다.
- 기존 DWM checker와 closeout checklist를 pre-amendment structural 기준으로 실행하고 결과를 closeout에 기록한다.

## Stage rewind 조건

- Plan이 기존 add/change 상태나 glossary trigger를 새 taxonomy로 바꾸면 Design으로 돌아간다.
- terminal 문면이 domain-specific behavior, B02 rule semantics, B04 일반 rewind를 흡수하면 Plan으로 돌아간다.
- successor absorption이 준비되지 않았는데 old Spec/implementation을 먼저 제거하도록 요구하면 affected lifecycle을 보존하고 Plan으로 돌아간다.
- actual domain 또는 global/user mutation이 필요해지면 generic changeset을 중단하고 해당 owner의 별도 승인 lifecycle로 분리한다.
