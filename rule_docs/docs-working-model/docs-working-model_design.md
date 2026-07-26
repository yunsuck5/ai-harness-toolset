# docs-working-model — live domain lifecycle Design

> 이 문서는 existing `docs-working-model` 규칙의 domain add/change 분류를 좁게 정렬하고 live domain retire·repeal·supersede lifecycle을 보강하는 임시 Design이다. 이 문서는 live 규칙, 실제 domain 처분, mutation/commit/push 승인이 아니며 closeout에서 삭제된다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현재 DWM은 incubation, promotion, `prelive`, `sync-required`, `live`, meaning-preserving direct edit, Spec↔implementation reconciliation을 이미 소유한다. Candidate discard와 promoted-but-not-live withdrawal도 구체적이다. 그러나 “Once live, change uses the normal repeal/supersede lifecycle”은 live domain 종료의 entry, retained meaning 흡수, old owner 처분, terminal과 resume를 정의하지 않는다.

이번 변경은 기존 add/change 채널을 보존하면서 다음 공백만 닫는다.

- implementation-only refactor와 Spec/rule prose의 meaning-preserving direct edit는 current synchronization·Proportionality 문면이 함께 구분하므로 그 채널을 변경 없이 보존한다.
- live domain retire/repeal, successor가 있는 supersede, identity rename/rehome을 candidate discard·promotion-withdrawal과 분리한다.
- old Spec, active implementation·routing, backlog·identity, 실제 stale reference, retained future work와 dependent work terminal을 owner-local하게 닫는다.
- 공용 용어의 실제 의미·분류 변화만 existing glossary trigger로 넘기고 domain-local 이름·설명은 상류 revision을 열지 않는다.
- 실제 안전한 live domain 처분 대상이 없으면 contract-only로 종결하고 source pilot과 deployed runtime pilot을 각각 미실증으로 남긴다.

## Owner surface model

- `rules/docs-working-model/docs-working-model.md`: 공통 artifact lifecycle, domain state, source-side retire/supersede terminal과 resume
- 각 domain Spec: durable target state와 stable interface
- 각 domain active implementation: observable behavior, trigger·routing과 owner-local validation
- 각 domain backlog: 아직 유효한 future work와 reopen condition
- successor owner: retained target meaning·interface·future work를 자기 lifecycle에서 흡수
- `rules/terminology-glossary.md`: 실제 프로젝트 공용 의미·분류 mutation의 네 trigger만 소유
- install/update/activation owner: source changeset과 분리된 installed/global runtime 처분

## 수정 대상

- `rules/docs-working-model/docs-working-model.md`
- `rules/docs-working-model/checklists/docs-working-model_closeout_checklist.md`
- `rule_docs/docs-working-model/docs-working-model_backlog.md`

실제 domain Spec·implementation·backlog·routing은 실제 처분 대상이 있을 때만 수정한다. Glossary는 네 mutation trigger가 실제로 발생할 때만 연다. DWM template/checker/tests는 새 결정 가능한 predicate나 직접 form/check dependency가 생길 때만 수정한다.

## 하지 않을 것 (non-goals)

- add/change lifecycle을 새 공통 state machine이나 중앙 actor registry로 대체하지 않는다.
- `retired` marker를 Spec에 추가하거나 삭제된 Spec을 tombstone authority로 남기지 않는다.
- B02의 terminal-rule path, clause/enforcement, tier index/bootstrap 의미를 domain lifecycle에 복제하지 않는다.
- B04가 소유할 일반 late-policy/minimum-affected rewind 계약을 선행 구현하지 않는다.
- 현재 live/prelive domain을 generic proof를 위해 수정·withdraw·retire하지 않는다.
- glossary reservation/pending 상태, broad reference scanner, global/user mutation을 만들지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔으며 Plan으로 진행할 수 있다.

- 현재 live domain 3개에는 모두 active owner가 있고 retire/supersede 결정이 없어 실제 처분 대상은 없다.
- modern `docs/<domain>/<domain>_spec.md` 삭제·rename 실사용은 0건이다. Legacy migration과 Chatlog residue 제거는 whole live-domain proof가 아니다.
- 현행 live Spec revision의 `live → sync-required → live` 반복 실증도 없다. 계약과 역사적 우회 사례를 구분해 보고한다.
- semantic absorption과 stale-reference 판정은 generic checker로 완전 기계화하지 않는다.
- governance self-revision closeout까지는 `49ac6b6bf5808b04600f8253534c3c6f878f7c0e`의 DWM이 지배한다.
