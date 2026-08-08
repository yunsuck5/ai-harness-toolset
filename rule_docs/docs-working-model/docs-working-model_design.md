# docs-working-model Design

> 이 문서는 docs-working-model backlog의 만료된 future-work 두 항목을 실제 사용 결과에 따라 처분하는 Design이다.
> 이 체인이 끝나면 E1의 runtime 경계 재평가가 종결되고, 지난 phase에 결박된 enforcement catch-all과 그 dangling 참조가 제거된다.
> 이 문서는 terminal rule 변경이나 mutation/commit/push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

`DWM-B-16`은 promoted-but-not-live active surface의 실제 dogfood에서 E1의 not-authority 경계와 runtime activation topology가 충분히 분리되는지 재평가하도록 남겨졌다. 실제 사용에서는 prelive 상태인 Blind가 설치·호출될 수 있으면서도 dogfood 자체가 governance status를 올리지 않았고, 별도 closeout 판단이 계속 필요했다. 따라서 E1을 다시 고칠 근거 없이 재평가 항목을 종결할 수 있다.

`DWM-B-06`은 여러 의미 조항의 enforcement 기계화를 `5-F 이후`라는 지난 phase에 한데 묶어 둔 catch-all이다. 현재 결정 가능한 재개 사건이나 구체 결함을 제공하지 않으며, 이를 새 문면으로 살리면 폐기된 inventory framing을 되살릴 수 있다. 해당 행을 제거하고 그 행과의 overlap만을 재개 조건 일부로 삼던 `DWM-B-07`의 참조를 의미 보존 정리한다.

## Owner surface model

- `rules/docs-working-model/docs-working-model.md`는 문서 lifecycle과 E1의 의미를 계속 소유하며 이번 변경으로 수정되지 않는다.
- `rule_docs/docs-working-model/docs-working-model_backlog.md`는 아직 시작하지 않은 DWM future work만 소유한다. 종료된 행은 삭제하고 살아 있는 행의 독립적인 reopen condition은 보존한다.
- Blind의 실행·closeout 의미는 Blind owner에 남는다. DWM은 dogfood 결과를 자기 backlog trigger 소비 근거로만 사용하고 Blind behavior를 흡수하지 않는다.

## 수정 대상

- `rule_docs/docs-working-model/docs-working-model_backlog.md`: `DWM-B-16`과 `DWM-B-06`을 제거하고 `DWM-B-07`의 삭제된 참조를 정리한다.
- 이 lifecycle의 Design/Plan: closeout에서 current-bearing 의미가 backlog 처분과 보고에 흡수됐는지 확인한 뒤 삭제한다.

## 하지 않을 것 (non-goals)

- terminal DWM rule, templates, checklists, checker, tests를 바꾸지 않는다.
- `DWM-B-14`를 실제 consumer 문제 없이 소급 종결하지 않는다.
- 새 schema, registry, scanner, checklist 또는 enforcement inventory를 만들지 않는다.
- Blind, Consultation, IU 또는 다른 owner의 behavior·backlog를 이 lifecycle에 흡수하지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔고 Plan으로 내려갈 준비가 됐다. 남은 위험은 삭제된 `DWM-B-06`을 가리키는 참조를 놓치는 것과 `DWM-B-14` 또는 next-ID floor를 우발적으로 바꾸는 것이다. Plan의 scope 회계와 closeout 검증에서 각각 닫는다.
