# Evidence and claim discipline Plan

> 이 문서는 `evidence-and-claim-discipline` terminal rule의 승인된 의미를 exact 7경로 candidate로 구현·검증하는 Plan이다. Work Packet은 만들지 않는다. 이 Plan은 mutation/commit/push/deploy/adoption 승인이 아니다.

## Header

Design에서 선택한 artifact admission, owner-gated prove-or-remove, consumer/function-bound risk naming을 하나의 self-contained distributed rule로 구현한다. Rule 본문은 영어를 유지하고, source-repo planning prose는 한국어로 작성한다.

## Batch 순서와 의존

단일 dependency-atomic batch로 진행한다.

1. Design·Plan을 먼저 current-bearing planning surface로 둔다.
2. Terminal rule 본문, rule index, 양 bootstrap trigger를 함께 추가한다.
3. Source rule→index→양 trigger 연결을 affected test로 결박한다.
4. affected-first validation과 corrected-state fresh canonical dual review로 candidate를 검증한다.

Rule만 추가하면 adopter가 trigger를 찾지 못하고, trigger만 추가하면 source owner가 없으므로 네 distributed surface와 회귀 test는 같은 batch다.

## Batch 정의

### Scope

| 상태 | 경로 | 역할 |
|---|---|---|
| A | `rule_docs/evidence-and-claim-discipline/evidence-and-claim-discipline_design.md` | 선택 의미·owner·non-goal |
| A | `rule_docs/evidence-and-claim-discipline/evidence-and-claim-discipline_plan.md` | exact batch·검증·rewind |
| A | `snippets/rules/evidence-and-claim-discipline.md` | adopter-universal active rule |
| M | `snippets/rules/README.md` | distributed rule index |
| M | `snippets/CLAUDE_SNIPPET.md` | Claude-compatible action trigger |
| M | `snippets/AGENTS_SNIPPET.md` | AGENTS-compatible action trigger |
| M | `tests/activate-global.Tests.ps1` | source/index/trigger routing regression |

이 terminal-rule revision의 actual foreign-Spec thin-interface direct-sync path set은 `∅`이고, Plan-declared foreign-Spec direct-sync-target path set도 `∅`이다. Aggregate/dependency 목록과 구별해 빈 집합까지 `A = D = ∅`로 reconcile했으며, 이번 candidate는 foreign Spec을 수정하지 않는다.

### Hard boundary

- Ordinary authorized read-only inspection, required workflow output, explicit acceptance evidence는 허용한다.
- 추가 persistent artifact·heightened precision은 explicit request, active contract, 또는 current consumer+protected failure로만 정당화한다.
- Prove-or-remove는 운영자/owner 사전 보고와 정상 revision gate를 요구하며 자동 삭제·비활성화 권한을 주지 않는다.
- Named risk·limitation은 consumer와 실패 기능을 식별하고, unknown은 missing evidence로 보고하되 일반적 우려를 blocker로 승격하지 않는다.
- 새 scanner·registry·hook·sidecar·hidden state·hash table·hard gate를 만들지 않는다.
- 7경로 밖 source mutation, full Pester, commit, push, deploy, re-adoption은 포함하지 않는다.

### Validation expectation

1. `tests/activate-global.Tests.ps1`만 먼저 실행해 source rule 존재, README index, 양 snippet의 단일·동일 trigger를 확인한다.
2. `tests/apply-managed-block.Tests.ps1`을 실행해 snippet marker-bounded apply 계약이 유지되는지 확인한다.
3. `scripts/verify-ps1.ps1`과 `scripts/docs-working-model-check.ps1 -ProjectRoot .`을 각각 child process로 실행한다.
4. `git diff --check`, exact 7-path status/index, Markdown UTF-8 no-BOM+LF, PowerShell UTF-8 BOM+CRLF, snippet marker/parity, rule-index/trigger residue를 확인한다.
5. 수정된 정확한 candidate에서 local-correctness와 system-coherence canonical review를 fresh unit으로 실행한다. Full Pester는 landing 승인 뒤 final unchanged candidate 경계로 보류한다.

### Review focus

- “혹시 필요할 수 있음”만으로 추가 artifact·hash·preimage를 요구하는 반례
- ordinary read-only inspection이나 명시된 acceptance evidence까지 잘못 금지하는 과대해석
- 비용·무효용 challenge 직후 owner 보고 없이 규칙을 삭제하는 무단 처분
- 기존 규칙이라는 사실 자체를 유지 evidence로 순환 사용하는 반례
- consumer나 실패 기능 없이 generic concern을 named risk·blocker로 승격하는 반례
- trigger가 지나치게 넓어 모든 조사·모든 risk 언급에서 rule을 강제하는 반례
- source rule, index, Claude/AGENTS bootstrap 중 하나가 빠지거나 비대칭인 배포 반례

Work Packet은 만들지 않는다. 필요한 조사·counterexample·scope 결정은 Design과 이 Plan에 충분히 흡수됐으며 별도 on-demand briefing artifact가 필요하지 않다.

## Open decision 의 close 지점

- 세 원칙을 하나의 규칙으로 묶을지: 공통 원인이 unsupported added claim이라는 Design 결정으로 닫혔다.
- Prove-or-remove의 제거 권한: 운영자/owner에게 먼저 보고하고 owner-local revision gate로만 처분하는 것으로 닫혔다.
- 자동 enforcement 여부: human/tool-readable binding rule만 두고 자동 detector·hard gate는 만들지 않는 것으로 닫혔다.
- 추가 evidence의 허용 경계: explicit request, active contract, 또는 concrete consumer+failure 중 하나로 닫혔다.

## Stage rewind 조건

- Rule이 ordinary inspection·required output을 금지하면 Design으로 rewind한다.
- Rule이 owner report/decision 없이 삭제·강등을 허용하면 Design으로 rewind한다.
- Trigger·index·source rule의 action class가 서로 다르거나 양 snippet이 비대칭이면 implementation을 교정한다.
- 7경로 밖 owner 의미가 필요하거나 새 자동 enforcement가 필요하면 즉시 멈추고 scope를 상신한다.
- Affected validation 또는 corrected-state review에서 7경로 안 concrete blocker가 나오면 자율 교정·재검증하고, 새 value judgment나 scope expansion이 필요할 때만 멈춘다.

## Lifecycle

Terminal rule 자체가 target-state spec이므로 별도 Spec은 없다. 이 Design과 Plan은 corrected-state review와 landing 승인 전까지 current-bearing이며, landing이 승인되면 기존 DWM closeout 절차에 따라 retire한다. 이번 Plan은 candidate+fresh dual report에서 끝나며 commit/push/deploy/re-adoption을 수행하지 않는다.
