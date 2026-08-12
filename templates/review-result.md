# Review Result

Reviewer가 verdict/disclosure body를 작성하는 compact skeleton이다. `review-run.ps1` preamble이 runtime output 지시를 제공하고, runner는 mechanically complete candidate에 machine provenance를 append한 뒤 final canonical shape를 다시 확인한다. provenance는 reviewer judgment가 아니며 result verifier의 provenance-content gate 대상도 아니다.

## Verdict

{{AI_TO_FILL_VERDICT}}

첫 비어 있지 않은 줄은 lowercase exact `yes`, `no`, `yes with risk` 중 하나다. Template은 어느 verdict도 default로 두지 않는다.

## Blocking findings

{{AI_TO_FILL_BLOCKING_FINDINGS}}

다음 승인 단계 전에 해결해야 하는 in-scope finding. `no`면 하나 이상, yes 계열이면 `none`.

## Non-blocking concerns

{{AI_TO_FILL_NON_BLOCKING_CONCERNS}}

blocking은 아니지만 사용자가 알아야 할 concern과 named risk의 단일 위치. `yes with risk`면 구체 risk와 closure/acceptance 필요를 여기 적고, 없으면 `none`.

## Review limitations

{{AI_TO_FILL_REVIEW_LIMITATIONS}}

직접 검증하지 못한 범위와 이유. 예: write/build/migration command가 read-only 또는 명시 authorization 경계 밖이었음, evidence freshness를 cross-execute하지 못함, 좁은 mechanical probe가 환경상 불가능했음. `verify-ps1.ps1`처럼 실제 read-only인 검사를 mutating command로 분류하지 않는다. 없으면 `none`.

## Assumptions relied on

{{AI_TO_FILL_ASSUMPTIONS}}

판단이 의존한 operator claim, evidence, source freshness, probe 결과 등의 전제. 전제가 깨지면 verdict가 stale임을 드러낸다. 없으면 `none`.

## Counter-argument

(optional, strongly-recommended; non-parser) yes 계열 verdict에 대한 strongest case AGAINST를 pressure-test한다. material counterexample이 없으면 `none` 또는 `no material counter-argument identified`처럼 짧게 쓰고 ceremonial boilerplate를 만들지 않는다. `no`에서는 Blocking findings가 case-against-yes이므로 생략할 수 있다.

## Notes

(optional) framing self-audit, evidence pointer, 후속 inspection 같은 freeform 관찰만 둔다.
