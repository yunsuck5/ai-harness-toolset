# Evidence and claim discipline Design

> 이 문서는 추가 증거·정밀도, 유지가 도전받은 규칙·반복 절차, risk·limitation claim을 하나의 adopter-universal 판단 규칙으로 묶는 terminal-rule Design이다. 최종 active 의미는 `snippets/rules/evidence-and-claim-discipline.md`가 소유하며, 이 Design은 closeout 때 삭제되는 planning artifact다. 이 문서는 mutation/commit/push/deploy/adoption 승인이 아니다.

## Header

Q-10에서 관측된 공통 결함은 “혹시 필요할 수 있다”는 이유만으로 산출물·정밀도·반복 비용을 늘리면서도, 그 비용이 보호하는 현재 consumer와 실패 기능은 특정하지 않는다는 점이다. 이 변경은 새 자동 gate가 아니라 사람이 추가 claim의 근거와 처분을 일관되게 판단하는 짧은 규칙을 도입한다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현재 운영에서는 세 현상이 같은 원인에서 반복될 수 있다.

1. 계약이 요구하지 않는 per-file hash, preimage, 별도 evidence report 같은 산출물과 정밀도가 안전을 이유로 추가된다.
2. 비용 또는 무효용이 관측된 규칙·review cycle·required artifact·recurring check가 “존재하므로 필요하다”는 순환 논리로 유지된다.
3. consumer와 실패 기능을 특정하지 않은 일반적 우려가 named risk·limitation·blocker로 승격되어 추가 작업을 정당화한다.

세 경우 모두 새로운 부담을 만드는 쪽이 그 부담의 현재 효용을 입증하지 않는다는 동일한 claim 문제다. 따라서 artifact admission, prove-or-remove, risk naming을 한 규칙에서 다루되 각 적용 조건과 권한 경계를 분리한다.

## 선택한 의미

1. **추가 산출물·정밀도 admission** — 사용자가 명시적으로 요구했거나, active contract·acceptance predicate가 요구했거나, 현재 consumer와 보호할 실패 기능이 구체적으로 식별된 경우에만 기존 계약을 넘는 persistent artifact 또는 heightened precision을 만든다. 승인된 ordinary read-only inspection, 선택한 workflow가 이미 요구하는 output, 사용자가 요구한 acceptance evidence는 그대로 허용한다. 명시 근거 없는 잠재적 미래 유용성만으로 산출물을 보존하지 않는다.
2. **prove-or-remove의 보고 및 owner gate** — 비용·무효용 evidence 때문에 기존 규칙·review cycle·required artifact·recurring check의 유용성이 도전받으면, 제거 후보 등록이나 삭제·강등 mutation보다 먼저 운영자/owner에게 관측 상황과 근거를 보고한다. 유지하는 쪽은 현재 consumer, 보호하는 실패 기능, 유지 효용의 evidence를 제시한다. 이를 제시하지 못하면 기본 제안 처분은 제거 또는 강등이지만, 실제 처분은 해당 owner의 정상 결정·revision gate를 거치며 자동 삭제·비활성화하지 않는다.
3. **risk·limitation claim** — named risk 또는 limitation은 영향을 받는 consumer와 실패할 수 있는 기능·결과를 함께 식별한다. 아직 알 수 없으면 unknown과 부족한 evidence를 보고할 수 있지만, 일반적 가능성만으로 blocker·필수 산출물·추가 정밀도를 만들지 않는다.
4. **판정 성격** — 이 규칙은 human/tool-readable decision rule이다. scanner, registry, hook, hidden state, evidence hash table, 새 자동 hard gate를 만들지 않는다.

## Owner surface model

- `snippets/rules/evidence-and-claim-discipline.md`가 위 세 판단과 권한 경계를 self-contained adopter-universal rule로 소유한다.
- `snippets/rules/README.md`는 distributed rule index에 파일을 등록한다.
- `snippets/CLAUDE_SNIPPET.md`와 `snippets/AGENTS_SNIPPET.md`는 같은 action-class trigger를 각각의 bootstrap에 byte-equivalent하게 싣는다.
- `tests/activate-global.Tests.ps1`은 source rule 존재, index 등록, 양 snippet의 단일·동일 trigger routing만 회귀 결박한다. 규칙의 상황별 semantic judgment를 regex가 증명한다고 주장하지 않는다.
- 이 Design과 Plan은 terminal-rule lifecycle을 소유하는 temporary planning artifact이며 별도 Spec은 만들지 않는다. Terminal rule 자체가 target-state spec이다.

## 영향을 받는 owner / interface

- Distributed rules tier에 adopter-universal active rule group을 둔다.
- Rule index와 양 bootstrap trigger가 그 rule group을 발견 가능한 action class로 연결한다.
- Activation regression이 source rule→index→양 trigger 배선을 확인한다.
- 정확한 batch path·상태·validation allocation은 Plan이 소유한다.

관측 incident, 시간·비용 측정치, relay 대화는 규칙의 runtime dependency나 durable pointer로 옮기지 않는다. 선택된 일반 의미만 distributed rule에 흡수하고 source residue는 planning rationale와 history에만 남긴다.

## 하지 않을 것 (non-goals)

- ordinary read-only inspection, 기존 workflow의 required output, 명시적 acceptance evidence를 금지하지 않는다.
- 효용이 도전받았다는 이유만으로 규칙·review cycle·artifact를 자동 삭제·비활성화하지 않는다.
- consumer와 실패 기능을 식별했다는 사실만으로 새 작업·mutation·commit·push 권한을 만들지 않는다.
- scanner, registry, hook, sidecar, hidden authority state, per-file evidence manifest, 자동 stale detector 또는 hard gate를 추가하지 않는다.
- Brief, consultation, blind-advisory 등 다른 도메인의 계약을 이번 batch에서 다시 쓰지 않는다.
- full Pester, commit, push, deploy, global/user activation 또는 re-adoption을 이번 candidate 작업에 포함하지 않는다.

## Plan readiness / open risks

선택 의미와 owner boundary는 Plan으로 내릴 수 있다. Plan은 exact scope를 정하고, 세 claim 축이 한 trigger로 과도하게 넓어지지 않는지, prove-or-remove가 무단 삭제 권한으로 읽히지 않는지, 양 snippet과 index가 source rule을 정확히 가리키는지를 affected-first 검증과 corrected-state review에서 닫는다. Plan-approved scope 밖 의미 변경이나 새 자동 enforcement 필요가 발견되면 mutation을 멈추고 scope를 다시 상신한다.
