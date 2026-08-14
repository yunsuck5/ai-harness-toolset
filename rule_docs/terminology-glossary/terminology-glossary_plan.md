# terminology-glossary Plan

> 이 문서는 W-18의 glossary meaning 변경을 owner-local하게 승인·검증하기 위한 Plan이다.
> DWM·Review lifecycle과 함께 exact 20-path aggregate candidate로 검증되지만, 이 Plan은 glossary terminal rule의 세 경로만 승인한다.
> 이 Plan은 commit/push/배포 승인이 아니며 W-18 자기 closeout은 개정 전 DWM과 별도 사용자 landing gate에 남는다.

## Batch 순서와 의존

1. **다섯 용어 disposition 확정**: `Implementation`·`Work Packet`·`sync-required`·`promoted-lifecycle closeout`을 새 DWM target meaning에 맞추고 `retirement-only closeout`을 채택한다.
2. **Single-home 정합**: glossary는 한 줄 의미만 보유하고 exact predicate·post-transaction marker 알고리즘을 DWM에 남긴다.
3. **Aggregate 검증과 review**: Review/DWM owner-local lifecycle과 함께 exact 20-path candidate에서 affected-first 구조 검증과 same-campaign corrected dual을 수행한다.

이 Plan은 glossary rule의 의미만 승인한다. DWM predicate와 Review behavior는 각각의 Design/Plan이 소유한다. Aggregate 검증은 dependency 정합을 확인하기 위한 것이며 owner 권한을 합치지 않는다.

## Exact owner-local path scope

| 상태 | 경로 |
|---|---|
| A | `rule_docs/terminology-glossary/terminology-glossary_design.md` |
| A | `rule_docs/terminology-glossary/terminology-glossary_plan.md` |
| M | `rules/terminology-glossary.md` |

W-18 aggregate scope는 Review 8경로 + DWM 9경로 + glossary 3경로의 총 20경로다. 이 Plan은 glossary 3경로만 승인한다. 사용자 직접 재정으로 추가된 DWM Plan checklist는 DWM owner-local Plan이 소유한다. Review·DWM·glossary 밖의 Brief·consultation·blind-advisory 등 다른 도메인 source mutation이 필요하면 즉시 중단하고 보고한다. Work Packet은 만들지 않는다.

## Batch 1 — Glossary meaning 정합

- 목적: 다섯 term의 채택 의미를 W-18 target state와 맞추고 독립 terminal-rule owner lifecycle을 충족한다.
- hard boundary: project-wide one-line meaning만 바꾸고 전체 DWM/review semantics를 복제하지 않는다.
- validation expectation: 각 용어의 변경 전·후 의미와 DWM owner의 대응 문장이 재구성되고, `retirement-only closeout`의 신규 채택이 candidate-local label이나 duplicate owner를 만들지 않아야 한다.
- review focus: meaning-preserving form sync로 가장한 foreign-owner 승인, `DWM-qualified`가 세부 predicate 복제가 되는지, 다섯 term 밖 unapproved reclassification, W-18 self-application.

## Batch 2 — Aggregate validation과 corrected candidate dual

- targeted-first: `tests/review-input-verify.Tests.ps1`, `tests/repo-local-instruction-parity.Tests.ps1`.
- structural: 환경에서 resolve한 skill-creator `quick_validate.py`로 Review SKILL frontmatter/package shape만 검사하고, `scripts/verify-ps1.ps1`, DWM diagnostic, `git diff --check`, strict encoding/EOL, root parity, relevant terminology/reference sweep, exact 20-path status와 index 0을 확인한다. Quick validator와 DWM diagnostic을 body-semantic proof로 과장하지 않는다.
- full Pester: correction loop에서는 실행하지 않는다. Landing이 승인된 변경 없는 final candidate boundary에만 남긴다.
- canonical review: 기존 W-18 campaign의 local/system 두 perspective를 같은 exact 20-path candidate에서 새 pass로 수행한다. 횟수 상한을 만들지 않고 Review·DWM·glossary 도메인 안의 approved-scope usable finding은 자율 교정·재검증·재리뷰한다. Brief·consultation·blind-advisory 등 다른 도메인 확대는 즉시 중단하고 보고한다.
- completion: glossary 5-term disposition, aggregate 검증, review 결과, 위임 사용 내역, 미실행 항목을 operator report에 기록한다.

## Open decision의 close 지점

- 다섯 term의 의미와 single-home 경계는 Batch 1에서 닫는다.
- Aggregate candidate fitness는 Batch 2 검증과 corrected-state dual에서 닫는다.
- W-18 introducing changeset은 개정 전 DWM이 자기 closeout까지 지배한다. 이번 범위에는 self-closeout·commit·push·deploy가 없다.
- 새 future-work disposition이 없어 glossary backlog와 Work Packet은 만들지 않는다.

## Stage rewind 조건

- 다섯 term 밖 project-wide meaning/classification 변경이 필요하면 Design으로 되돌린다.
- Glossary만으로 DWM/review behavior를 완성해야 하거나 새 checker·script·schema가 필요하면 중단하고 owner/scope를 재판정한다.
- W-18 자기 closeout에 새 retirement-only 의미를 소급 적용하려는 경우 개정 전 DWM 경계로 되돌린다.
